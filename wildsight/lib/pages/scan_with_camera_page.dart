import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:wildsight/database/animal_details_database.dart';
import 'package:wildsight/pages/animal_info_page.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class ScanWithCameraPage extends StatefulWidget {
  const ScanWithCameraPage({super.key});

  @override
  State<ScanWithCameraPage> createState() => _ScanWithCameraPageState();
}

class _ScanWithCameraPageState extends State<ScanWithCameraPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  // Set<String> animalsDetected = {
  //   "fajlsdjflajs;ldjfa;lskdj",
  //   "Monkey",
  //   "Lion",
  //   "Elephant",
  //   "Tiger",
  //   "Horse",
  //   "Bear"
  // };
  Set<dynamic> animalsDetected = {};

  // Map<String, Map<String, String>> animalDetails = {
  //   "Black Bear": {
  //     "animalImageUrl":
  //         "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQCetwCNbywkiIp9m7HHE9GSxeSybMwI0GCQMNQR3dUAVLNIVDP7bqLyDmsnWw-QsUNpuGGrfXFLq3DpV80AhQJ3A",
  //     "animalDescripiton":
  //         "A black bear is a medium-sized bear native to North America. Despite its name, its fur can range from black to brown, cinnamon, or even blonde. Black bears are omnivores, eating a variety of plants, fruits, insects, and small animals. They are excellent climbers and swimmers, and they typically live in forests, but can adapt to different habitats. Generally shy and solitary, black bears avoid humans but can become bold if they associate people with food."
  //   },
  //   "Tiger": {
  //     "animalImageUrl":
  //         "https://rukminim2.flixcart.com/image/850/1000/xif0q/shopsy-poster/r/j/u/medium-dm-205-tiger-paper-print-poster-animal-tiger-poster-sher-original-imagg494t5tkkxmv.jpeg?q=90&crop=false",
  //     "animalDescripiton":
  //         "A tiger is a large, powerful carnivorous cat known for its striking orange coat with black stripes. Native to Asia, it is the largest member of the cat family. Tigers are solitary hunters, primarily preying on deer and wild boar. They are strong swimmers and often found near water. Tigers are endangered due to habitat loss and poaching.",
  //   },
  // };

  Map<String, Map<String, String>> animalDetails =
      AnimalDetailsDatabase().animalDetails;

  File? _capturedImage;
  bool _imageCaptured = false;

  Future<String?> uploadToImgur(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://api.imgur.com/3/image"),
      headers: {
        "Authorization": "Client-ID 0db447f85e42579",
      },
      body: {
        "image": base64Image,
        "type": "base64",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json["data"]["link"];
    } else {
      print("Imgur upload failed: ${response.body}");
      return null;
    }
  }

  Future<void> _captureAndSendImage() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        final imgFile = File(image.path);

        if (!await imgFile.exists() || await imgFile.length() == 0) {
          print("Image capture failed or is empty");
          return;
        }
        setState(() {
          _capturedImage = imgFile; // Display it if needed
          _imageCaptured = true;
        });

        final bytes = await imgFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse(
              "https://lanuuk-wildsight.hf.space/gradio_api/call/predict"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "data": [
              {
                "url": "data:image/jpeg;base64,$base64Image",
                "name": "captured.jpg",
                "meta": {"_type": "gradio.FileData"}
              }
            ]
          }),
        );

        print("Body: ${response.body}");

        final eventId = jsonDecode(response.body)["event_id"];

        final eventResponse = await http.get(Uri.parse(
            "https://lanuuk-wildsight.hf.space/gradio_api/call/predict/$eventId"));

        print("Prediction: ${eventResponse.body}");

        final body = eventResponse.body;

        final dataLine = body.split('\n').firstWhere(
              (line) => line.trim().startsWith("data:"),
              orElse: () => '',
            );

        if (dataLine.isEmpty) {
          print("No data line found.");
          return;
        }

        // Remove the "data:" prefix
        final cleanJson = dataLine.replaceFirst("data:", "").trim();

        // Now parse JSON safely
        final List<dynamic> outerList = jsonDecode(cleanJson);
        final List<dynamic> innerList =
            outerList.isNotEmpty ? outerList[0] : [];

        print("Detected animals: $innerList");
        setState(() {
          animalsDetected = innerList.toSet();
        });
      }
    } catch (e) {
      print("Error during image detection: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.max,
      );

      final initFuture = controller.initialize();

      // Wait for camera to initialize, then assign to state
      await initFuture;

      setState(() {
        _cameraController = controller;
        _initializeControllerFuture = initFuture;
      });
    } catch (e) {
      print("Error setting up the camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("WildSight"),
      ),
      body: (_cameraController == null || _initializeControllerFuture == null)
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            _capturedImage == null
                                ? CameraPreview(_cameraController!)
                                : Image.file(_capturedImage!),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: FloatingActionButton(
                                  onPressed: _captureAndSendImage,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          height: 80,
                          child: animalsDetected.isEmpty
                              ? (!_imageCaptured
                                  ? Text("Capture an image")
                                  : Center(
                                      child: SizedBox(
                                        width: 40, // or whatever size you want
                                        height: 40,
                                        child: CircularProgressIndicator(),
                                      ),
                                    ))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: animalsDetected.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 10, top: 15, bottom: 15),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 16.0),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AnimalInfoPage(
                                                animalName: animalsDetected
                                                    .elementAt(index),
                                                animalImageUrl: animalDetails[
                                                            animalsDetected
                                                                .elementAt(
                                                                    index)]
                                                        ?["animalImageUrl"] ??
                                                    "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg?s=612x612&w=0&k=20&c=rnCKVbdxqkjlcs3xH87-9gocETqpspHFXu5dIGB4wuM=",
                                                animalDescription: animalDetails[
                                                            animalsDetected
                                                                .elementAt(
                                                                    index)]?[
                                                        "animalDescripiton"] ??
                                                    "No description of the animal",
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                            animalsDetected.elementAt(index)),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Camera error: ${snapshot.error}"));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
