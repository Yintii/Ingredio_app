import 'package:flutter/material.dart';
import 'package:ingredio/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = await ApiConfig.baseUrl;
    
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing token, please log in again")),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$url/auth/profile'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          userData = body;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint("Failed to load profile: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching profile: $e");
    }
  }

  Widget _buildInfoTile(String label, String? value) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? "Not provided"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("No profile data found"))
              : ListView(
                  children: [
                    _buildInfoTile("First Name", userData!["first_name"]),
                    _buildInfoTile("Last Name", userData!["last_name"]),
                    _buildInfoTile("Email", userData!["email"]),
                    _buildInfoTile("Birthday", userData!["birthday"]),
                    _buildInfoTile("Sex", userData!["sex"]),
                    _buildInfoTile("Skin Type", userData!["skin_type"]),
                    _buildInfoTile(
                      "Skin Issues",
                      (userData!["skin_issues"] as List<dynamic>).join(", "),
                    ),
                    _buildInfoTile(
                      "Allergies",
                      (userData!["allergies"] as List<dynamic>).join(", "),
                    ),
                    _buildInfoTile(
                      "Quiz Taken",
                      (userData!["has_taken_quiz"] == true) ? "Yes" : "No",
                    ),
                  ],
                ),
    );
  }
}
