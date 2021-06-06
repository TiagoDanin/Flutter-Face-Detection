import 'dart:ui';
import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  HomePageWithState createState() => HomePageWithState();
}

class HomePageWithState extends State<HomePage> {
  ui.Image imageSelected = null;
  List<Face> faces = [];

  void getImage() async {
    final PickedFile pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      var imageFile = await pickedFile.readAsBytes();
      ui.Image imageFile2 = await decodeImageFromList(imageFile);

      final InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
      final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
      ));

      final List<Face> outputFaces = await faceDetector.processImage(inputImage);

      setState(() {
        imageSelected = imageFile2;
        faces = outputFaces;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ML Kit Face Detection"),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(1000),
          minScale: 0.1,
          maxScale: 3,
          child: Column(
            children: [
              if (imageSelected != null)
                Container(
                  height: imageSelected.height.toDouble(),
                  width: imageSelected.width.toDouble(),
                  child: CustomPaint(
                    painter: FaceDraw(faces: faces, image: imageSelected),
                  ),
                )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Select',
        child: Icon(MdiIcons.image),
      ),
    );
  }
}

class FaceDraw extends CustomPainter {
  List<Face> faces;
  ui.Image image;

  FaceDraw({@required this.faces, @required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    for (Face face in faces) {
      canvas.drawRect(
        face.boundingBox,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.blueAccent
          ..strokeWidth = 4,
      );

      canvas.drawLine(
          Offset(face.boundingBox.left + 5, face.boundingBox.top - 12),
          Offset(face.boundingBox.right - 5, face.boundingBox.top - 12),
          Paint()
            ..color = Colors.white.withOpacity(0.8)
            ..strokeWidth = 18
            ..style = PaintingStyle.fill);

      TextPainter paintSpanId = new TextPainter(
        text: TextSpan(
          style: new TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto',
          ),
          text: "ID::${face.trackingId}",
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      paintSpanId.layout();
      paintSpanId.paint(canvas, new Offset(face.boundingBox.left + 10, face.boundingBox.top - 20));

      canvas.drawLine(
          Offset(face.boundingBox.left, face.boundingBox.bottom + 14),
          Offset(face.boundingBox.right, face.boundingBox.bottom + 14),
          Paint()
            ..color = Colors.black.withOpacity(0.7)
            ..strokeWidth = 20
            ..style = PaintingStyle.fill);

      TextPainter paintSmilingStatus = new TextPainter(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
          text: "Smiling::${face.smilingProbability >= 0.5 ? "Yes" : "No"}",
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      paintSmilingStatus.layout();
      paintSmilingStatus.paint(canvas, new Offset(face.boundingBox.left + 3, face.boundingBox.bottom + 5));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
