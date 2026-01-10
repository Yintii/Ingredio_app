import 'package:flutter/material.dart';
import 'package:ingredio/config/api_config.dart';
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
  String firstName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();
  }

  Future<void> _fetchUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final url = await ApiConfig.baseUrl;

    bool? localStatus = prefs.getBool('has_taken_quiz');
    final localFirst = prefs.getString('first_name');
    if (localFirst != null) {
      setState(() {
        firstName = localFirst;
      });
    }
    if (localStatus != null) {
      setState(() {
        hasTakenQuiz = localStatus;
      });
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
      Uri.parse('$url/auth/profile'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      bool taken = body['has_taken_quiz'] ?? false;
      final fetchedFirst = body['first_name'] as String?;
      if (fetchedFirst != null && fetchedFirst.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('first_name', fetchedFirst);
        setState(() {
          firstName = fetchedFirst;
        });
      }
      setState(() {
        hasTakenQuiz = taken;
      });
      await prefs.setBool('has_taken_quiz', taken);

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
    await prefs.remove('first_name');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF004730),
              ),
              child: Text(
                'Ingredio',
                style: TextStyle(color: Colors.white, fontSize: 48, fontFamily: 'LobsterTwo'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(firstName),
              onTap: () {
                Navigator.pop(context); // close drawer
                _profile(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // close drawer
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: hasTakenQuiz == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
              fit: StackFit.expand,
              children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Hello, $firstName!',
                            style: const TextStyle(
                              fontSize: 40,
                              fontFamily: 'LobsterTwo',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // other content can go here
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/scanner');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(
                        Icons.document_scanner,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
