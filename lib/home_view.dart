import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:object_detection_with_efficientnet_model/service/object_detection_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  late ObjectDetectionService _detectionService;
  File? _selectedImage;
  String result = '';
  dynamic image; // For drawing rectangles
  List<DetectedObject> detectedObjects = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _detectionService = ObjectDetectionService();
  }

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => isLoading = true);
      _selectedImage = (source == ImageSource.gallery)
          ? await _detectionService.pickImageFromGallery()
          : await _detectionService.pickImageFromCamera();

      if (_selectedImage != null) {
        detectedObjects = await _detectionService.processImage(_selectedImage!);
        _generateResult();
        await _drawObjectsOnImage();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _drawObjectsOnImage() async {
    try {
      image = await _selectedImage?.readAsBytes();
      image = await decodeImageFromList(image);
    } catch (e) {
      log(e.toString());
    }
  }

  void _generateResult() {
    result = detectedObjects
        .map((obj) => obj.labels
            .map((label) =>
                "${label.text} (${(label.confidence * 100).toStringAsFixed(1)}%)")
            .join(", "))
        .join("\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF20002c),
                  Color(0xFFcbb4d4),
                ]),
              ),
              child: Column(
                children: [
                  const SizedBox(width: 100),
                  Container(
                    margin: const EdgeInsets.only(top: 100),
                    child: Stack(
                      children: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            onLongPress: () => _pickImage(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent),
                            child: Container(
                              width: 350,
                              height: 350,
                              margin: const EdgeInsets.only(top: 45),
                              child: image != null
                                  ? Center(
                                      child: FittedBox(
                                        child: SizedBox(
                                          width: image.width.toDouble(),
                                          height: image.height.toDouble(),
                                          child: CustomPaint(
                                            painter: ObjectPainter(
                                                objectList: detectedObjects,
                                                imageFile: image),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white,
                                      width: 350,
                                      height: 350,
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 53,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: Text(
                      result.isEmpty ? 'No Objects Detected' : result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'finger_paint',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    Paint p = Paint();
    p.color = const Color(0xFFcbb4d4);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4;

    for (DetectedObject rectangle in objectList) {
      canvas.drawRect(rectangle.boundingBox, p);
      var list = rectangle.labels;
      for (Label label in list) {
        log("${label.text}   ${label.confidence.toStringAsFixed(2)}");
        TextSpan span = TextSpan(
            text: label.text,
            style: const TextStyle(
              fontSize: 25,
              color: Colors.blue,
              fontWeight: FontWeight.w700,
            ));
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas,
            Offset(rectangle.boundingBox.left, rectangle.boundingBox.top));
        break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
