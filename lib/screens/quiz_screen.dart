import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum QuestionType { multipleChoice, textInput, datePicker, checkList }

class QuestionItem {
  final int questionNumber;
  final String questionText;
  final QuestionType type;
  final List<String>? answerChoices;

  const QuestionItem(
    this.questionNumber,
    this.questionText,
    this.type,
    this.answerChoices,
  );
}

class QuizScreen extends StatefulWidget {
  QuizScreen({super.key});

  final List<QuestionItem> questions = [
    QuestionItem(1, "What is your name?", QuestionType.textInput, null),
    QuestionItem(2, "When is your birthday?", QuestionType.datePicker, null),
    QuestionItem(3, "What is your sex?", QuestionType.multipleChoice, ["Female", "Male"]),
    QuestionItem(4, "What skin type do you have?", QuestionType.multipleChoice, [
      "Normal",
      "Oily",
      "Dry"
    ]),
    QuestionItem(5, "Check all skin issues that apply to you", QuestionType.checkList, [
      "Acne",
      "Cystic Acne",
      "Acne Scarring",
      "Eczema",
      "Rough Texture",
      "Flakey",
      "Fine Lines",
      "Clogged Pores",
      "None of the Above"
    ]),
    QuestionItem(6, "Check all known allergies", QuestionType.checkList, [
      "Tree Nut",
      "Silicon",
      "Egg",
      "Dairy",
      "Dust",
      "Mold",
      "Mushroom",
      "None of the Above"
    ]),
  ];

  final Map<int, dynamic> answers = {};

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  bool quizStarted = false;
  final String? url = dotenv.env['API_BASE_URL'];

  String? selectedAnswer;
  List<String> selectedCheckList = [];
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? selectedDate;

  Future<void> submitAnswers() async {
    debugPrint("Attempting to submit answers...");

    final nameAnswer = widget.answers[1] as Map<String, String>;
    final payload = {
      "firstName": nameAnswer["firstName"],
      "lastName": nameAnswer["lastName"],
      "birthday": widget.answers[2],
      "sex": widget.answers[3] == "Male" ? "M" : "F",
      "skin_issues": widget.answers[5],
      "allergies": widget.answers[6],
      "skin_type_id": widget.answers[4],
    };

    debugPrint("Submitting payload: $payload");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if(token == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token, please log in again")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('$url/auth/submit_quiz'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Successfully submitted data');
      await prefs.setBool('has_taken_quiz', true);

      // Redirect to home page after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    } else {
      debugPrint('❌ Failed to submit data: ${response.body}');
    }
  }

  void nextQuestion(QuestionItem question) {
    if (question.questionNumber == 1) {
      widget.answers[question.questionNumber] = {
        "firstName": _firstNameController.text,
        "lastName": _lastNameController.text,
      };
      _firstNameController.clear();
      _lastNameController.clear();
    } else {
      switch (question.type) {
        case QuestionType.textInput:
          widget.answers[question.questionNumber] = _textController.text;
          _textController.clear();
          break;
        case QuestionType.datePicker:
          widget.answers[question.questionNumber] = selectedDate;
          selectedDate = null;
          break;
        case QuestionType.multipleChoice:
          widget.answers[question.questionNumber] = selectedAnswer;
          selectedAnswer = null;
          break;
        case QuestionType.checkList:
          widget.answers[question.questionNumber] = List<String>.from(selectedCheckList);
          selectedCheckList.clear();
          break;
      }
    }

    if (currentIndex < widget.questions.length) {
      setState(() {
        currentIndex++;
      });
    }

    if (currentIndex >= widget.questions.length) {
      debugPrint("Quiz finished! Answers: ${widget.answers}");
      submitAnswers();
      setState(() {});
    }
  }

  void prevQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  bool isAnswered(QuestionItem question) {
    if (question.questionNumber == 1) {
      final f = _firstNameController.text.trim();
      final l = _lastNameController.text.trim();
      return f.length >= 3 &&
          f.length <= 15 &&
          l.length >= 3 &&
          l.length <= 15;
    }
    switch (question.type) {
      case QuestionType.textInput:
        return _textController.text.trim().isNotEmpty;
      case QuestionType.datePicker:
        return selectedDate != null;
      case QuestionType.multipleChoice:
        return selectedAnswer != null;
      case QuestionType.checkList:
        return selectedCheckList.isNotEmpty;
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!quizStarted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Welcome to the Quiz"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      quizStarted = true;
                    });
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (currentIndex >= widget.questions.length) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ListView(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              children: [
                const Text(
                  "Quiz Finished!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text("You will be redirected to the home page in 5 seconds."),
                const SizedBox(height: 16),
                ...widget.questions.map((q) {
                  final answer = widget.answers[q.questionNumber];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text("Q${q.questionNumber}: ${q.questionText}\nAnswer: $answer"),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }

    final question = widget.questions[currentIndex];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height / 2,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Q${question.questionNumber}: ${question.questionText}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (question.questionNumber == 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: TextField(
                          onChanged: (_) => setState(() {}),
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "First Name",
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: TextField(
                          onChanged: (_) => setState(() {}),
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Last Name",
                          ),
                        ),
                      ),
                    ],
                    if (question.type == QuestionType.textInput && question.questionNumber != 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Enter your answer",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    if (question.type == QuestionType.datePicker) ...[
                      ElevatedButton(
                        onPressed: pickDate,
                        child: const Text("Pick a Date"),
                      ),
                      if (selectedDate != null) Text("Selected: $selectedDate"),
                    ],
                    if (question.type == QuestionType.multipleChoice)
                      ...question.answerChoices!.map(
                        (choice) => RadioListTile<String>(
                          title: Text(choice),
                          value: choice,
                          groupValue: selectedAnswer,
                          onChanged: (value) {
                            setState(() {
                              selectedAnswer = value;
                            });
                          },
                        ),
                      ),
                    if (question.type == QuestionType.checkList)
                      ...question.answerChoices!.map(
                        (choice) => CheckboxListTile(
                          title: Text(choice),
                          value: selectedCheckList.contains(choice),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedCheckList.add(choice);
                              } else {
                                selectedCheckList.remove(choice);
                              }
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: currentIndex > 0 ? () => prevQuestion() : null,
                          child: const Text("Prev"),
                        ),
                        const SizedBox(width: 50),
                        ElevatedButton(
                          onPressed: isAnswered(question)
                              ? () => nextQuestion(question)
                              : null,
                          child: Text(
                            currentIndex == widget.questions.length - 1 ? 'Finish' : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
