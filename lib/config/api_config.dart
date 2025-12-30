import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiConfig {
  static Future<String> get baseUrl async {
    final deviceInfo = DeviceInfoPlugin();

    // iOS
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final isPhysicalDevice = iosInfo.isPhysicalDevice;

      return isPhysicalDevice
          ? dotenv.env['NGROK_URL']!
          : dotenv.env['API_BASE_URL']!;
    }

    // Android
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isPhysicalDevice = androidInfo.isPhysicalDevice;

      return isPhysicalDevice
          ? dotenv.env['NGROK_URL']!
          : dotenv.env['API_BASE_URL']!;
    }

    // Web / Desktop fallback
    return dotenv.env['API_BASE_URL']!;
  }
}
