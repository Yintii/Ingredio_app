import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? hasTakenQuiz;
  final String? url = dotenv.env['API_BASE_URL'];

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();
  }

  Future<void> _fetchUserStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Check local first
    bool? localStatus = prefs.getBool('has_taken_quiz');
    if (localStatus != null) {
      setState(() {
        hasTakenQuiz = localStatus;
      });
      // Redirect if quiz not taken
      if (!localStatus) {
        _redirectToQuiz();
      }
      return;
    }

    final token = prefs.getString('jwt_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token, please log in again")),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('$url/auth/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      bool taken = body['has_taken_quiz'] ?? false;
      setState(() {
        hasTakenQuiz = taken;
      });
      // Save locally
      await prefs.setBool('has_taken_quiz', taken);

      // Redirect if quiz not taken
      if (!taken) {
        _redirectToQuiz();
      }
    } else {
      setState(() {
        hasTakenQuiz = false; // fallback
      });
      debugPrint('Failed to fetch user status: ${response.body}');
    }
  }

  void _redirectToQuiz() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/quiz');
    });
  }

  Future<void> _profile(BuildContext context) async {
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('has_taken_quiz');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _profile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: hasTakenQuiz == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Welcome to the app"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/scanner');
                      },
                      child: const Text('Scan Ingredients'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
