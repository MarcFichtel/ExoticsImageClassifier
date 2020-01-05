package com.razzymcsnazzy.tarantula_identifier;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import androidx.annotation.NonNull;

import com.google.firebase.FirebaseApp;
import com.google.firebase.ml.common.FirebaseMLException;
import com.google.firebase.ml.common.modeldownload.FirebaseModelDownloadConditions;
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.automl.FirebaseAutoMLLocalModel;
import com.google.firebase.ml.vision.automl.FirebaseAutoMLRemoteModel;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabel;
import com.google.firebase.ml.vision.label.FirebaseVisionImageLabeler;
import com.google.firebase.ml.vision.label.FirebaseVisionOnDeviceAutoMLImageLabelerOptions;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Flutter's Firebase AutoML plugin does not yet support custom models, so use native
 *   Android library to perform classification.
 *
 * Ref: https://firebase.google.com/docs/ml-kit/android/label-images-with-automl?authuser=0
 */
public class MainActivity extends FlutterActivity {
  private static final String CLASSIFIER_CHANNEL = "classifier";
  private static final String CLASSIFIER_MODEL = "min100_20191228";
  private static final String CLASSIFY_START_METHOD = "startClassification";
  private static final String CLASSIFY_UPDATE_METHOD = "doneClassification";
  private static final String IMAGE_BYTES_ARG = "imageBytes";
  private static final Float CONFIDENCE_THRESHOLD = 0.1f;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    final BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
    new MethodChannel(messenger, CLASSIFIER_CHANNEL).setMethodCallHandler((call, result) -> {
      try {
        if (call.method.equals(CLASSIFY_START_METHOD)) {
          final byte[] imageBytes = call.argument(IMAGE_BYTES_ARG);
          GetModel(imageBytes, messenger);
          result.success(true);
        } else {
          result.notImplemented();
        }
      } catch (Exception e) {
        result.error("Error", e.getMessage(), e);
      }
    });
  }

  /**
   * Get the model.
   * Once the model is available, classify the given image.
   * If the model isn't on the device, or if a newer version of the model is available, the task
   *   will asynchronously download the model from Firebase.
   *
   * TODO some DRY to clean up here between callbacks
   */
  private void GetModel(final byte[] imageBytes, final BinaryMessenger messenger) {

    // init remote model or fall back to local model
    try {
      FirebaseApp.initializeApp(this);

      // To download something, wifi is needed
      final FirebaseModelDownloadConditions conditions = new FirebaseModelDownloadConditions.Builder().requireWifi().build();
      final FirebaseAutoMLRemoteModel remoteModel = new FirebaseAutoMLRemoteModel.Builder(CLASSIFIER_MODEL).build();

      FirebaseModelManager.getInstance().isModelDownloaded(remoteModel).addOnSuccessListener(isDownloaded -> {

        // Model has not yet been downloaded
        if (!isDownloaded) {
          FirebaseModelManager.getInstance().download(remoteModel, conditions)

            // Success downloading remote model
            .addOnSuccessListener((Void unusedParam) -> {
              try {
                ClassifyImage(imageBytes, GetRemoteModelLabeler(remoteModel), messenger);
              } catch (FirebaseMLException e) {
                e.printStackTrace();
              }
            })

            // Error downloading remote model, fall back to local one
            .addOnFailureListener((Exception e) -> {
              e.printStackTrace();
              try {
                ClassifyImage(imageBytes, GetLocalModelLabeler(), messenger);
              } catch (FirebaseMLException e2) {
                e2.printStackTrace();
              }
            });
        }

        // Use already downloaded remote model
        else {
          try {
            ClassifyImage(imageBytes, GetRemoteModelLabeler(remoteModel), messenger);
          } catch (FirebaseMLException e) {
            e.printStackTrace();
          }
        }
      });

    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  /**
   * Get labeler for a remote model.
   * @param remoteModel to get labeler for
   * @return the labeler
   * @throws FirebaseMLException if something goes wrong
   */
  private FirebaseVisionImageLabeler GetRemoteModelLabeler(final FirebaseAutoMLRemoteModel remoteModel) throws FirebaseMLException {
    final FirebaseVisionOnDeviceAutoMLImageLabelerOptions options = new FirebaseVisionOnDeviceAutoMLImageLabelerOptions
            .Builder(remoteModel).setConfidenceThreshold(CONFIDENCE_THRESHOLD).build();
    return FirebaseVision.getInstance().getOnDeviceAutoMLImageLabeler(options);
  }

  /**
   * Get labeler for a local model.
   * @return the labeler
   * @throws FirebaseMLException if something goes wrong
   */
  private FirebaseVisionImageLabeler GetLocalModelLabeler() throws FirebaseMLException {
    final FirebaseAutoMLLocalModel localModel = new FirebaseAutoMLLocalModel
            .Builder().setAssetFilePath("manifest.json").build();
    final FirebaseVisionOnDeviceAutoMLImageLabelerOptions options = new FirebaseVisionOnDeviceAutoMLImageLabelerOptions
            .Builder(localModel).setConfidenceThreshold(CONFIDENCE_THRESHOLD).build();
    return FirebaseVision.getInstance().getOnDeviceAutoMLImageLabeler(options);
  }

  /**
   * Classify an image using a given labeler.
   */
  private void ClassifyImage(final byte[] imageBytes, final FirebaseVisionImageLabeler labeler, final BinaryMessenger messenger) throws InternalError {

    // prepare image
    final Bitmap bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
    final FirebaseVisionImage image = FirebaseVisionImage.fromBitmap(bitmap);

    // label (i.e. classify) image
    final Map<String, Double> result = new HashMap<>();
    labeler.processImage(image)
            .addOnSuccessListener(labels -> {
              for (FirebaseVisionImageLabel label: labels) {
                final String text = label.getText();
                final Double confidence = Math.round(label.getConfidence() * 10000.0) / 100.0;
                result.put(text, confidence);
              }
              new MethodChannel(messenger, CLASSIFIER_CHANNEL).invokeMethod(CLASSIFY_UPDATE_METHOD, result);
            }).addOnFailureListener(e -> {
              throw new InternalError("Unexpected error while classifying image: " + e);
            });
  }
}
