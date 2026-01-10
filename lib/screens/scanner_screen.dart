import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../helpers/image_preview.dart';
import './scan_results_screen.dart';

class ScannerScreen extends StatefulWidget {
  ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late TextRecognizer textRecognizer;
  late ImagePicker imagePicker;

  String? pickedImagePath;
  String recognizedText = "";

  bool isRecognizing = false;

  @override
  void initState() {
    super.initState();

    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    imagePicker = ImagePicker();
  }

  Future<File?> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: "Crop Image",
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: false,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: "Crop Image",
          ),
        ],
      );

    if(croppedFile == null) return null;
    return File(croppedFile.path);
  }

  void _pickImageAndProcess({required ImageSource source}) async {
    final pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage == null) {
      return;
    }

    final croppedFile = await _cropImage(pickedImage.path);
    if(croppedFile == null) return;

    setState(() {
      pickedImagePath = croppedFile.path;
      isRecognizing = true;
    });

    try {
      final inputImage = InputImage.fromFile(croppedFile);
      final RecognizedText recognisedText = //with a s
          await textRecognizer.processImage(inputImage);

      recognizedText = ""; //with a z

      for (TextBlock block in recognisedText.blocks) {
        for (TextLine line in block.lines) {
          recognizedText += "${line.text}\n";
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recognizing text: $e'),
        ),
      );
    } finally {
      if (recognizedText != ""){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultsScreen(
              imagePath: pickedImagePath!,
              recognizedText: recognizedText,
            ),
          ),
        );
      }
      setState(() {
        isRecognizing = false;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false, // ensure proper gesture handling
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  debugPrint('Gallery Tapped');
                  Navigator.of(context).pop();
                  _pickImageAndProcess(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageAndProcess(source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyTextToClipboard() async {
    if (recognizedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: recognizedText));
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ImagePreview(imagePath: pickedImagePath),
            ),
            ElevatedButton(
              onPressed: isRecognizing ? null : () async {
                await Future.delayed(Duration.zero);
                _showImageSourceOptions();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pick an image'),
                  if (isRecognizing) ...[
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ],
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }  
}