import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart'; 
import 'screens/registration_screen.dart'; 
import 'screens/login_screen.dart'; 
import 'screens/TOS_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ingredio',
      debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 20.0, color: Colors.white),
            headlineMedium: TextStyle(fontSize: 28.0, color: Colors.white),
            headlineLarge: TextStyle(fontSize: 58.0, color: Colors.white),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF004730),
            brightness: Brightness.dark,
            primary: const Color(0xFF006A4E),
            secondary: const Color(0xFFEDC988),
          ),
          scaffoldBackgroundColor: const Color(0xFF004730),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A4E),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: const Color(0xFF006A4E).withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: const Color(0xFF006A4E), width: 2.0),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
      ),
      home: const AuthGate(),
      routes: {
        '/quiz': (context) => QuizScreen(),
        // scanner removed: use HomeScreen scan button to pick image
        '/registration': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/terms': (context) => TOSScreen(),
        '/profile': (context) => ProfileScreen(),
      }
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // you could also validate expiry by calling your backend /auth/me
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? HomeScreen() : LoginScreen();
  }
}
