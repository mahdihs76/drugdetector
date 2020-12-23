import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:demo/ScannerUtils.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

import 'TextDetectorPainter.dart';

class OCRPage extends StatefulWidget {
  @override
  _OCRPageState createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _camera == null
            ? Container(
                color: Colors.black,
              )
            : Container(
                height: MediaQuery.of(context).size.height - 200,
                child: CameraPreview(_camera)),
        _buildResults(_textScanResults),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width,
                    height: 100,
                    child: Column(
                      children: [
                        Text(
                          _textScanResults == null ? "" : _textScanResults.text,
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _textScanResults == null ? "" : getExpiryDate(_textScanResults.text),
                          style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      ],
                    )),
              ],
            ),
          ],
        ),
      ],
    ));
  }

  getExpiryDate(String text){
    if (text == null) return "";
    RegExp regExp = new RegExp(
      r"\d{4}-\d{2}-\d{2}",
      caseSensitive: false,
      multiLine: true,
    );
    return regExp.firstMatch(text).toString();
  }

  Widget _buildResults(VisionText scanResults) {
    CustomPainter painter;
    if (scanResults != null) {
      final Size imageSize = Size(
        _camera.value.previewSize.height - 100,
        _camera.value.previewSize.width,
      );
      painter = TextDetectorPainter(imageSize, scanResults);

      return CustomPaint(
        painter: painter,
      );
    } else {
      return Container();
    }
  }

  bool _isDetecting = false;

  VisionText _textScanResults;

  CameraLensDirection _direction = CameraLensDirection.back;

  CameraController _camera;

  final TextRecognizer _textRecognizer =
      FirebaseVision.instance.textRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      ResolutionPreset.high,
    );

    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      setState(() {
        _isDetecting = true;
      });
      ScannerUtils.detect(
        image: image,
        detectInImage: _getDetectionMethod(),
        imageRotation: description.sensorOrientation,
      ).then(
        (results) {
          setState(() {
            if (results != null) {
              setState(() {
                _textScanResults = results;
              });
            }
          });
        },
      ).whenComplete(() => _isDetecting = false);
    });
  }

  Future<VisionText> Function(FirebaseVisionImage image) _getDetectionMethod() {
    return _textRecognizer.processImage;
  }
}
