import 'package:flutter/material.dart';

class ScanWithCameraWidget extends StatelessWidget {
  const ScanWithCameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
          color: Colors.grey[300], borderRadius: BorderRadius.circular(30),),
          
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.camera_alt, size: 100, color: Colors.black45),
            Text("Scan with Camera",style: TextStyle(fontSize: 15),),
          ],
        ),
      ),
    );
  }
}
