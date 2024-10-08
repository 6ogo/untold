import 'dart:io';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading to Firebase Storage
import 'package:path_provider/path_provider.dart'; // Can be removed if not using local paths

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  Future<void> _uploadToFirebase(String filePath) async {
    // Reference to Firebase Storage
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    File file = File(filePath);

    try {
      // Upload file to Firebase Storage
      await firebaseStorageRef.putFile(file);
      String downloadUrl = await firebaseStorageRef.getDownloadURL();
      debugPrint('File uploaded successfully: $downloadUrl');
    } catch (e) {
      debugPrint('Failed to upload file: $e');
    }
  }

  Future<SingleCaptureRequest> _buildPhotoPath(Sensor sensor) async {
    // Create a temporary directory to hold the captured media
    // We still need to create a temporary path for camerawesome to store the file before uploading
    final Directory extDir = await getTemporaryDirectory();
    final Directory tempDir = await Directory('${extDir.path}/temp_camerawesome').create(recursive: true);

    final String filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    return SingleCaptureRequest(filePath, sensor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          onMediaCaptureEvent: (event) {
            event.captureRequest.when(
              single: (single) async {
                debugPrint('Captured media path: ${single.file?.path}');
                if (single.file != null) {
                  await _uploadToFirebase(single.file!.path);
                  // After uploading, you can also delete the local file if you want:
                  // File(single.file!.path).deleteSync();
                }
              },
              multiple: (multiple) {
                multiple.fileBySensor.forEach((sensor, file) async {
                  debugPrint('Captured media path (multiple sensors): ${file?.path}');
                  if (file != null) {
                    await _uploadToFirebase(file.path);
                    // After uploading, you can delete the local file:
                    // File(file.path).deleteSync();
                  }
                });
              },
            );
          },
          saveConfig: SaveConfig.photoAndVideo(
            initialCaptureMode: CaptureMode.photo,
            photoPathBuilder: (sensors) async {
              if (sensors.length == 1) {
                return _buildPhotoPath(sensors.first);
              } else {
                // Using single sensor for now, but you could handle multiple sensors similarly
                return _buildPhotoPath(sensors.first);
              }
            },
            videoOptions: VideoOptions(
              enableAudio: true,
              ios: CupertinoVideoOptions(fps: 30),
              android: AndroidVideoOptions(
                bitrate: 6000000,
                fallbackStrategy: QualityFallbackStrategy.lower,
              ),
            ),
            exifPreferences: ExifPreferences(saveGPSLocation: true),
          ),
          sensorConfig: SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back), // Using the back camera
            flashMode: FlashMode.auto,
            aspectRatio: CameraAspectRatios.ratio_4_3,
            zoom: 0.0, // No initial zoom
          ),
          enablePhysicalButton: true, // Use volume keys for capture
          previewFit: CameraPreviewFit.contain,
          previewAlignment: Alignment.center,
          onMediaTap: (mediaCapture) async {
            // Optional: tap on the captured media to upload if needed
            mediaCapture.captureRequest.when(
              single: (single) async {
                debugPrint('Tapped media: ${single.file?.path}');
                if (single.file != null) {
                  await _uploadToFirebase(single.file!.path);
                }
              },
              multiple: (multiple) {
                multiple.fileBySensor.forEach((sensor, file) async {
                  debugPrint('Tapped media (multiple sensors): ${file?.path}');
                  if (file != null) {
                    await _uploadToFirebase(file.path);
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }
}
