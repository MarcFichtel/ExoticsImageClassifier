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
  private static final Float CONFIDENCE_THRESHOLD = 0.1f;


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
          result.success(true);
        } else {
          result.notImplemented();
        }
      } catch (Exception e) {
        result.error("Error", e.getMessage(), e); }
      });
  }

  /**
   * TODO
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
    final FirebaseVisionImage image = FirebaseVisionImage.fromBitmap(bitmap);

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
