package com.razzymcsnazzy.tarantula_classifier;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;

import com.google.android.gms.tasks.Task;

import com.google.firebase.FirebaseApp;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.common.modeldownload.FirebaseLocalModel;
import com.google.firebase.ml.common.modeldownload.FirebaseModelDownloadConditions;
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager;
import com.google.firebase.ml.common.modeldownload.FirebaseRemoteModel;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabeler;
import com.google.firebase.ml.vision.label.FirebaseVisionOnDeviceAutoMLImageLabelerOptions;
import com.google.firebase.perf.metrics.AddTrace;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String CLASSIFIER_CHANNEL = "classifier";
  private static final String CLASSIFIER_MODEL_V2 = "min100_20190706";
  private static final String CLASSIFY_START_METHOD = "startClassification";
  private static final String CLASSIFY_UPDATE_METHOD = "updateClassification";
  private static final String IMAGE_BYTES_ARG = "imageBytes";
  private static final Float CONFIDENCE_THRESHOLD = 0.5f;
//  private static final String PROJECT_ID = "tarantula-identifier";
//  private static final String COMPUTE_REGION = "us-central1";
//  private static final String MODEL_ID = "ICN4654330636948075705";


  /**
   * Register plugin on app startup.
   * @param savedInstanceState from flutter app
   */
  @Override
  protected void onCreate(final Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CLASSIFIER_CHANNEL).setMethodCallHandler((call, result) -> {
      try {
        if (call.method.equals(CLASSIFY_START_METHOD)) {
          final byte[] imageBytes = call.argument(IMAGE_BYTES_ARG);
          classifyImageLocally(imageBytes);
//          classifyImageOnline(imageBytes);
          result.success(true);
        } else {
          result.notImplemented();
        }
      } catch (Exception e) {
        result.error("Error", e.getMessage(), e); }
      });
  }


  // TODO how to use this code on android?
//  private void classifyImageOnline(final byte[] imageBytes) throws IOException {
//
//    System.out.println("START");
//
//    // Instantiate client for prediction service.
//    final PredictionServiceClient predictionClient = PredictionServiceClient.create();
//
//    System.out.println("DONE INIT PREDICTION SERVICE");
//
//    // Get the full path of the model.
//    final ModelName name = ModelName.of(PROJECT_ID, COMPUTE_REGION, MODEL_ID);
//
//    System.out.println("DONE GETTING MODEL NAME");
//
//    // Read the image and assign to payload.
//    final ByteString content = ByteString.copyFrom(imageBytes);
//    final Image image = Image.newBuilder().setImageBytes(content).build();
//    final ExamplePayload examplePayload = ExamplePayload.newBuilder().setImage(image).build();
//
//    System.out.println("DONE PREPPING IMAGE");
//
//    // Additional parameters that can be provided for prediction e.g. Score Threshold
//    final Map<String, String> params = new HashMap<>();
//    params.put("score_threshold", CONFIDENCE_THRESHOLD.toString());
//    // Perform the AutoML Prediction request
//    final PredictResponse response = predictionClient.predict(name, examplePayload, params);
//
//    System.out.println("Prediction results:");
//    for (AnnotationPayload annotationPayload : response.getPayloadList()) {
//      System.out.println("Predicted class name :" + annotationPayload.getDisplayName());
//      System.out.println(
//          "Predicted class score :" + annotationPayload.getClassification().getScore());
//    }
//  }

  /**
   * TODO
   *   need to worry about image rotation???
   *   why are results so different from online results???
   *
   * Classify an image using a model on the Android device.
   * @param imageBytes of image to classify
   * @throws FirebaseMLException if there's an error getting the labeler
   * @throws InternalError if there's an error classifying the image
   */
  @AddTrace(name = "trace_classify_image")
  private void classifyImageLocally(final byte[] imageBytes) throws FirebaseMLException, InternalError {

    // init remote and local models
    FirebaseApp.initializeApp(this);
    final FirebaseModelDownloadConditions conditions = new FirebaseModelDownloadConditions.Builder().requireWifi().build();
    final FirebaseRemoteModel remoteModel = new FirebaseRemoteModel.Builder(CLASSIFIER_MODEL_V2)
        .enableModelUpdates(true)
        .setInitialDownloadConditions(conditions)
        .setUpdatesDownloadConditions(conditions)
        .build();
    final FirebaseLocalModel localModel = new FirebaseLocalModel.Builder(CLASSIFIER_MODEL_V2)
        .setAssetFilePath("ml-model/manifest.json")
        .build();
    FirebaseModelManager.getInstance().registerLocalModel(localModel);
    FirebaseModelManager.getInstance().registerRemoteModel(remoteModel);
    FirebaseModelManager.getInstance().downloadRemoteModelIfNeeded(remoteModel)
        .addOnFailureListener(e -> { throw new InternalError("Error downloading remote model: " + e); });

    // prepare image
    Bitmap bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
    final int imageWidth = bitmap.getWidth();
    final int imageHeight = bitmap.getHeight();
    final FirebaseVisionImageMetadata metadata = new FirebaseVisionImageMetadata.Builder()
        .setFormat(FirebaseVisionImageMetadata.IMAGE_FORMAT_NV21)
        .setWidth(imageWidth)
        .setHeight(imageHeight)
        .build();
    final FirebaseVisionImage image = FirebaseVisionImage.fromByteArray(imageBytes, metadata);

    // get labeler
    final FirebaseVisionOnDeviceAutoMLImageLabelerOptions labelerOptions =
        new FirebaseVisionOnDeviceAutoMLImageLabelerOptions.Builder()
            .setLocalModelName(CLASSIFIER_MODEL_V2)
            .setRemoteModelName(CLASSIFIER_MODEL_V2)
            .setConfidenceThreshold(CONFIDENCE_THRESHOLD)
            .build();
    final FirebaseVisionImageLabeler labeler = FirebaseVision.getInstance()
        .getOnDeviceAutoMLImageLabeler(labelerOptions);

    // label (i.e. classify) image
    final Map<String, Double> result = new HashMap<>();
    final Task<List<FirebaseVisionImageLabel>> task = labeler.processImage(image);

    // this executes asynchronously
    // thus method returns before classification is done
    // solved by calling a method in main.dart from here once done
    task.addOnSuccessListener(labels -> {
      for (FirebaseVisionImageLabel label: labels) {
        final String text = label.getText();
        final Double confidence = Math.round(label.getConfidence() * 10000.0) / 100.0;
        result.put(text, confidence);
      }
      new MethodChannel(getFlutterView(), CLASSIFIER_CHANNEL).invokeMethod(CLASSIFY_UPDATE_METHOD, result);
    }).addOnFailureListener(e -> {
      throw new InternalError("Error classifying image: " + e);
    });
  }
}
