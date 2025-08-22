import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class TOSScreen extends StatefulWidget {
  const TOSScreen({super.key});

  @override
  State<TOSScreen> createState() => _TOSScreenState();
}

class _TOSScreenState extends State<TOSScreen> {
  String _terms = "";

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    final termsText = await rootBundle.loadString('assets/terms.md');
    setState(() {
      _terms = termsText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms of Service")),
      body: _terms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _terms,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                p: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
    );
  }
}
