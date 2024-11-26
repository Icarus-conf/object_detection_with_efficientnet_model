import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ObjectDetectionService {
  late ObjectDetector _objectDetector;
  final ImagePicker _imagePicker = ImagePicker();

  ObjectDetectionService() {
    _initializeObjectDetector();
  }

  Future<void> _initializeObjectDetector() async {
    final modelPath = await _getModel('assets/ml/efficientnet_model.tflite');
    final options = LocalObjectDetectorOptions(
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
      mode: DetectionMode.single,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<String> _getModel(String asset) async {
    try {
      final path = '${(await getApplicationSupportDirectory()).path}/$asset';
      await Directory(dirname(path)).create(recursive: true);
      final file = File(path);
      if (!await file.exists()) {
        final byteData = await rootBundle.load(asset);
        await file.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      return file.path;
    } catch (e) {
      throw Exception("Error loading model: $e");
    }
  }

  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) return File(pickedFile.path);
    } catch (e) {
      log("Error picking image: $e");
    }
    return null;
  }

  Future<File?> pickImageFromCamera() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) return File(pickedFile.path);
    } catch (e) {
      log("Error picking image: $e");
    }
    return null;
  }

  Future<List<DetectedObject>> processImage(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      return await _objectDetector.processImage(inputImage);
    } catch (e) {
      log("Error during object detection: $e");
      rethrow;
    }
  }

  void dispose() {
    _objectDetector.close();
  }
}
