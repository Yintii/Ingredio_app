import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ingredio/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;


  

  @override
  void initState(){
    super.initState();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // On Android emulator, replace localhost with 10.0.2.2
    // if (apiBase.contains("localhost") && Theme.of(context).platform == TargetPlatform.android) {
    //   apiBase = apiBase.replaceAll("localhost", "10.0.2.2");
    // }

    final _email = _emailController.text.trim();
    final _password = _passwordController.text.trim();

    if(_email == '' || _password == ''){
      setState(() {
        _errorMessage = "Must enter both an email and a password!";
        _isLoading = false;
      });
      return;
    }


    final url = await ApiConfig.baseUrl;

    final loginUrl = '$url/login';
      final bodyJson = jsonEncode({
      "email": _email,
      "password": _password,
    });

    debugPrint("Attempting login to: $loginUrl");
    debugPrint("Request body: $bodyJson");

    try {
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {"Content-Type": "application/json"},
            body: bodyJson,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("Response status: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        final body = jsonDecode(response.body);
        setState(() => _errorMessage = body['error'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint("Exception during login: $e");
      setState(() => _errorMessage = "Something went wrong: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingredient Checker"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: TextField(
                  key: const Key('emailField'),
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: TextField(
                  key: const Key('passwordField'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                  ),
                ),
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      key: const Key('loginButton'),
                      onPressed: _login,
                      child: const Text("Login"),
                    ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  child: const Text(
                    "Don't have an account? Register here",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
