import 'package:flutter/material.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _processIngredients();
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
    Color color;

    if (hasWarning && hasHelp) {
      message = 'Mixed results for your skin profile.';
      color = Colors.orange.shade50;
    } else if (hasWarning) {
      message = 'Some ingredients may irritate your skin.';
      color = Colors.red.shade50;
    } else if (hasHelp) {
      message = 'Ingredients appear beneficial for your skin issues!';
      color = Colors.green.shade50;
    } else {
      message = 'No significant effects detected.';
      color = Colors.grey.shade200;
    }

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: hasWarning ? Colors.orange : Colors.green,
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
                textColor = Colors.black;
              } else if (effects.any((e) => e.contains('worsen') || e.contains('irritate'))) {
                textColor = Colors.red;
              } else if (effects.any((e) => e.contains('Helps'))) {
                textColor = Colors.green;
              } else {
                textColor = Colors.orange;
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
