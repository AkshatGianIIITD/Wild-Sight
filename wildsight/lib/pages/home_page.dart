import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wildsight/pages/scan_with_camera_page.dart';
import 'package:wildsight/pages/upload_from_gallery_page.dart';
import 'package:wildsight/utils/scan_with_camera_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wildsight/pages/upload_from_gallery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final _picker = ImagePicker();

  pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final selectedImage = File(pickedFile.path);

      Fluttertoast.showToast(
        msg: "An image has been selected",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadFromGalleryPage(image: selectedImage),
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: "No image selected",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 50,
            ),
            GestureDetector(
                child: ScanWithCameraWidget(),
                onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScanWithCameraPage(), // Replace with your screen/widget
                      ),
                    )),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                pickImage();
              },
              child: Text("Upload from Gallery"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text("Past Sightings >"),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
