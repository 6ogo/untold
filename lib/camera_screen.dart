import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // Import for File handling

// Get a reference to the storage service
final storage = FirebaseStorage.instance;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  XFile? _capturedImage; // To store the captured image

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller.initialize();
    setState(() {});
  }

  Future<void> _captureImage() async {
    try {
      _capturedImage = await _controller.takePicture();
      setState(() {}); // Update UI to show captured image
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_capturedImage != null) {
      final file = File(_capturedImage!.path);
      final ref = storage.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg'); // Unique filename

      try {
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('Image uploaded successfully! Download URL: $downloadUrl');
        // You can use the downloadUrl to display the image in your app or share it
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller),
          if (_capturedImage != null)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.file(File(_capturedImage!.path)),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _captureImage,
            child: const Icon(Icons.camera),
          ),
          const SizedBox(width: 16),
          if (_capturedImage != null)
            FloatingActionButton(
              onPressed: _uploadImageToFirebase,
              child: const Icon(Icons.upload_file),
            ),
        ],
      ),
    );
  }
}