import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wildsight/database/animal_details_database.dart';
import 'package:wildsight/pages/animal_info_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadFromGalleryPage extends StatefulWidget {
  final File image;

  const UploadFromGalleryPage({super.key, required this.image});

  @override
  State<UploadFromGalleryPage> createState() => _UploadFromGalleryPageState();
}

class _UploadFromGalleryPageState extends State<UploadFromGalleryPage> {
  Set<dynamic> animalsDetected = {};
  bool _imageProcessed = false;

  Map<String, Map<String, String>> animalDetails =
      AnimalDetailsDatabase().animalDetails;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final bytes = await widget.image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse("https://lanuuk-wildsight.hf.space/gradio_api/call/predict"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data": [
            {
              "url": "data:image/jpeg;base64,$base64Image",
              "name": "uploaded.jpg",
              "meta": {"_type": "gradio.FileData"}
            }
          ]
        }),
      );

      final eventId = jsonDecode(response.body)["event_id"];

      final eventResponse = await http.get(
        Uri.parse("https://lanuuk-wildsight.hf.space/gradio_api/call/predict/$eventId"),
      );

      final body = eventResponse.body;
      final dataLine = body.split('\n').firstWhere(
        (line) => line.trim().startsWith("data:"),
        orElse: () => '',
      );

      if (dataLine.isEmpty) return;

      final cleanJson = dataLine.replaceFirst("data:", "").trim();
      final List<dynamic> outerList = jsonDecode(cleanJson);
      final List<dynamic> innerList =
          outerList.isNotEmpty ? outerList[0] : [];

      setState(() {
        animalsDetected = innerList.toSet();
        _imageProcessed = true;
      });
    } catch (e) {
      print("Error during image upload/detection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uploaded Image"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              widget.image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 80,
              child: animalsDetected.isEmpty
                  ? (!_imageProcessed
                      ? const Center(child: CircularProgressIndicator())
                      : const Text("No animals detected"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: animalsDetected.length,
                      itemBuilder: (context, index) {
                        final name = animalsDetected.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimalInfoPage(
                                    animalName: name,
                                    animalImageUrl: animalDetails[name]
                                            ?["animalImageUrl"] ??
                                        "https://media.istockphoto.com/id/1147544807/vector/thumbnail-image-vector-graphic.jpg",
                                    animalDescription: animalDetails[name]
                                            ?["animalDescripiton"] ??
                                        "No description available.",
                                  ),
                                ),
                              );
                            },
                            child: Text(name),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
