import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  final List<Widget> _overlayIcons = [];
  Offset _dragPosition = Offset.zero;
  double _rotationAngle = 0;
  bool _isFlipped = false;

  Future<void> _pickImage() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          await _cropImage(pickedFile.path);
        }
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied. Unable to access storage.')),
      );
    }
  }

  Future<void> _cropImage(String filePath) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        _showImageDialog(croppedFile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image')),
        );
      }
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image')),
      );
    }
  }

  void _showImageDialog(CroppedFile image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _image = XFile(image.path);
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Use this image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle += pi / 4; // Rotate by 45 degrees
    });
  }

  void _flipImage() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _addIconToImage(IconData icon) {
    setState(() {
      _overlayIcons.add(Icon(icon, size: 50, color: Colors.white));
    });
  }

  Widget _buildImage() {
    if (_image == null) {
      return Text('No image selected.');
    } else {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(_isFlipped ? pi : 0)
          ..rotateZ(_rotationAngle),
        child: Stack(
          children: [
            Image.file(
              File(_image!.path),
              fit: BoxFit.cover,
            ),
            ..._overlayIcons.map((icon) => Positioned(
              left: _dragPosition.dx,
              top: _dragPosition.dy,
              child: Draggable(
                feedback: icon,
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    _dragPosition = details.offset;
                  });
                },
                child: icon,
              ),
            )),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Add Images/ Icons')),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: Center(child: Text('Choose from Device')),
          ),
          if (_image != null)
            Center(
              child: Container(
                margin: EdgeInsets.all(10),
                height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
                width: MediaQuery.of(context).size.width * 0.6, // 60% of screen width 
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: _buildImage(),
              ),
            ),
        ],
      ),
    );
  }
}
