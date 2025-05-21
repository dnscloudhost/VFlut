// lib/services/app_settings_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';

/// سرویس برای دریافت تنظیمات و feature flags اپ
class AppSettingsApi {
  static const String _baseUrl = 'https://5891-2a03-90c0-5f1-2903-00-951.ngrok-free.app';
  static const String _token   = '26|dhcAmNOaXR2GSsNIkCIt9RsvzFcSkzUPCsAZ8uBRf29385f5';

  /// دریافت تنظیمات اپ از API
  static Future<AppSettings> fetchSettings() async {
    final uri = Uri.parse('$_baseUrl/api/applications');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_token',
    });
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch app settings: ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    if (list.isEmpty) {
      throw Exception('No app settings returned');
    }
    return AppSettings.fromJson(list.first as Map<String, dynamic>);
  }
}
