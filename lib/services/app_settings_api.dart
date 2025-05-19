// lib/services/app_settings_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';

class AppSettingsApi {
  static const _baseUrl =
      'https://designed-georgia-banner-threats.trycloudflare.com/api/applications';
  static const _token =
      '26|dhcAmNOaXR2GSsNIkCIt9RsvzFcSkzUPCsAZ8uBRf29385f5';

  static Future<AppSettings> fetch() async {
    final res = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch app settings: ${res.statusCode}');
    }
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;
    return AppSettings.fromJson(data);
  }
}
