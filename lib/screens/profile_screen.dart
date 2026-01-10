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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: ListTile(
          dense: true,
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value ?? "Not provided"),
        ),
      ),
    );
  }

  String _initials() {
    final first = (userData?['first_name'] as String?) ?? '';
    final last = (userData?['last_name'] as String?) ?? '';
    final parts = '${first.trim()} ${last.trim()}'.trim().split(' ');
    if (parts.isEmpty) return '';
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  }

  String _listDisplay(String key) {
    final val = userData?[key];
    if (val == null) return 'None';
    if (val is List) {
      if (val.isEmpty) return 'None';
      return val.map((e) => e.toString()).join(', ');
    }
    final s = val.toString();
    return s.isEmpty ? 'None' : s;
  }

  String _formatBirthday(dynamic b) {
    if (b == null) return '🎂 Not provided';
    try {
      DateTime dt;
      if (b is String) {
        dt = DateTime.parse(b);
      } else if (b is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(b);
      } else if (b is DateTime) {
        dt = b;
      } else {
        return '🎂 ${b.toString()}';
      }

      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      return '🎂 $mm/$dd/$yyyy';
    } catch (e) {
      return '🎂 ${b.toString()}';
    }
  }

  String _formatSex(dynamic s) {
    if (s == null) return '⚧ Not provided';
    final str = s.toString().trim();
    if (str.isEmpty) return '⚧ Not provided';
    final lower = str.toLowerCase();
    if (lower == 'male' || lower == 'm') return '♂️ Male';
    if (lower == 'female' || lower == 'f') return '♀️ Female';
    return '⚧ ${str[0].toUpperCase()}${str.substring(1)}';
  }

  String _formatSkinType(dynamic st) {
    if (st == null) return '🧴 Not provided';
    final str = st.toString().trim();
    if (str.isEmpty) return '🧴 Not provided';
    // simple title-case
    final parts = str.split(RegExp(r'\s+')).map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').toList();
    return '🧴 ${parts.join(' ')}';
  }

  Future<void> _confirmRetake() async {
    final doIt = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retake quiz'),
        content: const Text('This will clear your quiz data and allow you to retake the quiz. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (doIt == true) {
      await _retakeQuiz();
    }
  }

  Future<void> _retakeQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = await ApiConfig.baseUrl;
    if (token == null) return;

    try {
      final res = await http.post(
        Uri.parse('$url/auth/reset_quiz'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        await prefs.setBool('has_taken_quiz', false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz reset. Redirecting to quiz...')));
        Navigator.pushReplacementNamed(context, '/quiz');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reset quiz: ${res.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showEditProfileSheet() {
    final first = TextEditingController(text: userData!['first_name'] as String? ?? '');
    final last = TextEditingController(text: userData!['last_name'] as String? ?? '');
    final birthday = TextEditingController(text: userData!['birthday'] as String? ?? '');
    final sex = TextEditingController(text: userData!['sex'] as String? ?? '');
    final skinType = TextEditingController(text: userData!['skin_type'] as String? ?? '');
    final skinIssues = TextEditingController(text: (userData!['skin_issues'] as List<dynamic>).join(', '));
    final allergies = TextEditingController(text: (userData!['allergies'] as List<dynamic>).join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: first, decoration: const InputDecoration(labelText: 'First name')),
                TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name')),
                TextField(controller: birthday, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
                TextField(controller: sex, decoration: const InputDecoration(labelText: 'Sex')),
                TextField(controller: skinType, decoration: const InputDecoration(labelText: 'Skin type (name)')),
                TextField(controller: skinIssues, decoration: const InputDecoration(labelText: 'Skin issues (comma separated)')),
                TextField(controller: allergies, decoration: const InputDecoration(labelText: 'Allergies (comma separated)')),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'firstName': first.text.trim(),
                      'lastName': last.text.trim(),
                      'birthday': birthday.text.trim(),
                      'sex': sex.text.trim(),
                      'skin_type_id': skinType.text.trim(),
                      'skin_issues': skinIssues.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                      'allergies': allergies.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                    };

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('jwt_token');
                    final url = await ApiConfig.baseUrl;
                    if (token == null) return;

                    try {
                      final res = await http.patch(
                        Uri.parse('$url/auth/profile'),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                        body: jsonEncode(payload),
                      ).timeout(const Duration(seconds: 10));

                      if (res.statusCode == 200) {
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                        _fetchProfile();
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: ${res.body}')));
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData == null
                ? const Center(child: Text("No profile data found"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with back button, avatar and name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white12,
                              child: Text(_initials(), style: const TextStyle(fontSize: 24, color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userData!["first_name"] ?? ''} ${userData!["last_name"] ?? ''}'.trim(),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(userData!["email"] ?? '', style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: Builder(builder: (ctx) {
                                final seedColor = Theme.of(ctx).colorScheme.primary;
                                return OutlinedButton.icon(
                                  icon: Icon(Icons.edit, color: seedColor),
                                  label: Text('Edit Profile', style: TextStyle(color: seedColor)),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.0)),
                                  ),
                                  onPressed: () => _showEditProfileSheet(),
                                );
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retake Quiz'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () => _confirmRetake(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Profile info cards
                        _buildInfoTile("Birthday", _formatBirthday(userData!["birthday"])),
                        const SizedBox(height: 8),
                        _buildInfoTile("Sex", _formatSex(userData!["sex"])),
                        const SizedBox(height: 8),
                        _buildInfoTile("Skin Type", _formatSkinType(userData!["skin_type"])),
                        const SizedBox(height: 8),
                        _buildInfoTile(
                          "Skin Issues",
                          _listDisplay('skin_issues'),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoTile(
                          "Allergies",
                          _listDisplay('allergies'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
