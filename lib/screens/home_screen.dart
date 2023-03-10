import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import '../main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  int cameraNum = 0;

  loadCamera() async {
    cameraController =
        CameraController(camera![cameraNum], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        var _timer = Timer.periodic(Duration(milliseconds: 600), (timer) {
          if (!cameraController!.value.isStreamingImages) {
            setState(() {
              cameraController!.startImageStream((imageStream) async {
                cameraImage = imageStream;
                runModel();
              });
            });
          }
        });
      }
    });
  }

  runModel() async {
    if (cameraImage != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true,
        ).then((value) {
          for (var element in value!) {
            setState(() {
              output = element['label'];
            });
          }
        }).catchError((e) {
          print(
              'Model inference failed: $e ----------------------------------');
        });
      });
    }
  }

  loadModel() async {
    Tflite.close();

    await Tflite.loadModel(
      model: 'assets/model/model_unquant.tflite',
      labels: 'assets/model/labels.txt',
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadCamera();
    loadModel();
  }

  @override
  void dispose() {
    cameraController!.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Emotion Detector',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * .7,
              width: MediaQuery.of(context).size.width * .9,
              child: !cameraController!.value.isInitialized
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(
                        cameraController!,
                      ),
                    ),
            ),
          ),
          Text(
            output,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          // ElevatedButton(
          //     onPressed: () {
          //       setState(() {
          //         cameraNum == 0 ? 1 : 0;
          //       });
          //     },
          //     child: Icon(Icons.flip_camera_android))
        ],
      ),
    );
  }
}
