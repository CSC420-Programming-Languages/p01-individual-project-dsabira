import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:io';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key, required this.picture}) : super(key: key);

  final XFile picture;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _loading = false;
  String? _predictedClass;
  List? _recognitions;

  @override
  void initState() {
    super.initState();
    _loading = true;

    setState(() {
      _predictedClass = "Loading model";
    });
    loadModel().then((value) async {
      var recognitions = await Tflite.runModelOnImage(
        path: widget.picture.path,
        numResults: 2,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      setState(() {
        _predictedClass = "Analyzing the prediction";
      });

      String? predictedClass;
      double confidence = 0;

      if (recognitions != null) {
        for (final res in recognitions) {
          if (res["confidence"] >= confidence) {
            confidence = res["confidence"];
            predictedClass = res["label"];
          }
        }

        setState(() {
          _loading = false;
          _recognitions = recognitions;
          _predictedClass = recognitions.isNotEmpty
              ? predictedClass
              : "Recognition list is empty";
        });
      } else {
        setState(() {
          _loading = false;
          _recognitions = recognitions;
          _predictedClass = "No recognitions available";
        });
      }
    });
  }

  Future classifyImage(File image) async {
    setState(() {
      _predictedClass = "Running model on image";
    });
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _predictedClass = "Analyzing the prediction";
    });

    String? predictedClass;
    double confidence = 0;

    recognitions?.map((res) {
      if (res["confidence"] >= confidence) {
        confidence = res["confidence"];
        predictedClass = res["label"];
      }
    });

    setState(() {
      _loading = false;
      _recognitions = recognitions;
      _predictedClass = predictedClass;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/damaged_detection_model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Page')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.file(File(widget.picture.path), fit: BoxFit.cover, width: 250),
          const SizedBox(height: 24),
          (_predictedClass != null)
              ? Text(_predictedClass!)
              : const Text("Processing image...")
        ]),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
