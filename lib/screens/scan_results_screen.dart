import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Dummy DB check helpers for illustration — replace with your actual backend/API calls
Future<List<String>> getIngredientsFromDb(List<String> parsedIngredients) async {
  // Simulate fetching ingredient info
  // Return only recognized ingredient names from DB
  // Replace with your real DB/API call
  final knownIngredients = ['selenium sulfide', 'sodium lauryl sulfate', 'water'];
  return parsedIngredients.where((i) => knownIngredients.contains(i.toLowerCase())).toList();
}


///to be done next when my computer is set up

/// Dummy check for conflicts with user's skin issues
Future<Map<String, List<String>>> getIngredientConflicts(List<String> ingredients) async {
  // key = ingredient, value = list of conflicts
  final map = <String, List<String>>{};
  for (final ing in ingredients) {
    if (ing.toLowerCase() == 'sodium lauryl sulfate') {
      map[ing] = ['May worsen dry skin'];
    } else if (ing.toLowerCase() == 'selenium sulfide') {
      map[ing] = ['Helps dandruff'];
    } else {
      map[ing] = [];
    }
  }
  return map;
}

class ScanResultsScreen extends StatefulWidget {
  final String imagePath;
  final String recognizedText;

  const ScanResultsScreen({
    super.key,
    required this.imagePath,
    required this.recognizedText,
  });

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  Map<String, List<String>> ingredientReport = {};
  bool isLoading = true;

  late TextRecognizer textRecognizer;
  late ImagePicker imagePicker;
  bool isRecognizing = false;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    imagePicker = ImagePicker();
    _processIngredients();
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> _processIngredients() async {
    setState(() => isLoading = true);

    // 1. Parse recognized text into ingredients (split by commas and newlines)
    final parsedIngredients = widget.recognizedText
        .split(RegExp(r'[,\\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 2. Fetch ingredients from DB (filter out unknowns)
    final knownIngredients = await getIngredientsFromDb(parsedIngredients);

    // 3. Check for conflicts / effects on skin issues and allergies
    final report = await getIngredientConflicts(knownIngredients);

    setState(() {
      ingredientReport = report;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: isRecognizing
                ? null
                : () async {
                    await Future.delayed(Duration.zero);
                    _showImageSourceOptions();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductSummaryCard(imagePath: widget.imagePath),
                    const SizedBox(height: 16),
                    _OverallVerdictCard(ingredientReport: ingredientReport),
                    const SizedBox(height: 16),
                    _IngredientsCard(ingredientReport: ingredientReport),
                  ],
                ),
              ),
      ),
    );
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

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  void _pickImageAndProcess({required ImageSource source}) async {
    final pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage == null) {
      return;
    }

    final croppedFile = await _cropImage(pickedImage.path);
    if (croppedFile == null) return;

    setState(() {
      isRecognizing = true;
    });

    String recognizedText = "";

    try {
      final inputImage = InputImage.fromFile(croppedFile);
      final RecognizedText recognisedText =
          await textRecognizer.processImage(inputImage);

      for (TextBlock block in recognisedText.blocks) {
        for (TextLine line in block.lines) {
          recognizedText += "${line.text}\\n";
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recognizing text: $e')),
      );
    } finally {
      if (recognizedText.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultsScreen(
              imagePath: croppedFile.path,
              recognizedText: recognizedText,
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          isRecognizing = false;
        });
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListTileTheme(
            textColor: Colors.black,
            iconColor: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
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
          ),
        );
      },
    );
  }
}

/// --- UI Components ---

class _ProductSummaryCard extends StatelessWidget {
  final String imagePath;

  const _ProductSummaryCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scanned Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ingredient Analysis Report',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallVerdictCard extends StatelessWidget {
  final Map<String, List<String>> ingredientReport;

  const _OverallVerdictCard({required this.ingredientReport});

  @override
  Widget build(BuildContext context) {
    // Determine overall verdict
    final hasWarning = ingredientReport.values.any((v) => v.isNotEmpty && !v.contains('Helps dandruff'));
    final hasHelp = ingredientReport.values.any((v) => v.contains('Helps dandruff'));

    String message;

    if (hasWarning && hasHelp) {
      message = 'Mixed results for your skin profile.';
    } else if (hasWarning) {
      message = 'Some ingredients may irritate your skin.';
    } else if (hasHelp) {
      message = 'Ingredients appear beneficial for your skin issues!';
    } else {
      message = 'No significant effects detected.';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: hasWarning ? Colors.orangeAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientsCard extends StatelessWidget {
  final Map<String, List<String>> ingredientReport;

  const _IngredientsCard({required this.ingredientReport});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recognized Ingredients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...ingredientReport.entries.map((entry) {
              final ingredient = entry.key;
              final effects = entry.value;

              Color textColor;
              if (effects.isEmpty) {
                textColor = Colors.white;
              } else if (effects.any((e) => e.contains('worsen') || e.contains('irritate'))) {
                textColor = Colors.redAccent;
              } else if (effects.any((e) => e.contains('Helps'))) {
                textColor = Colors.greenAccent;
              } else {
                textColor = Colors.orangeAccent;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(ingredient, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    if (effects.isNotEmpty)
                      Expanded(
                        child: Text(
                          effects.join(', '),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
