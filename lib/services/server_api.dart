// lib/services/server_api.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/locations.dart';

/// سرویس برای دریافت و دسته‌بندی سرورهای VPN
class ServerApi {
  static const String _baseUrl = 'https://75e7-2a03-90c0-5f1-2903-00-951.ngrok-free.app';
  static const String _token   = '26|dhcAmNOaXR2GSsNIkCIt9RsvzFcSkzUPCsAZ8uBRf29385f5';

  /// ۱. دریافت سرورهای ریموت از API
  static Future<List<LocationConfig>> _fetchRemoteServers() async {
    final uri = Uri.parse('$_baseUrl/api/servers');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_token',
    });
    if (resp.statusCode != 200) {
      throw Exception('Failed to load servers: ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => LocationConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// ۲. بارگذاری همه سرورها (لوکال + ریموت)، با فُک بک به لوکال در صورت خطا
  static Future<List<LocationConfig>> loadAllServers() async {
    try {
      final remote = await _fetchRemoteServers();
      return [...localConfigs, ...remote];
    } catch (e, st) {
      debugPrint('ServerApi.loadAllServers error: $e\n$st');
      return List<LocationConfig>.from(localConfigs);
    }
  }

  /// سازگاری با کدهای قدیمی که loadAll صدا می‌زدند
  static Future<List<LocationConfig>> loadAll() => loadAllServers();

  /// ۳. فیلتر سرورهای Smart
  static List<LocationConfig> getSmartServers(List<LocationConfig> servers) {
    return servers
        .where((s) => s.serverType.toLowerCase() == 'smart')
        .toList();
  }

  /// ۴. فیلتر سرورهای Normal و Pro
  static List<LocationConfig> getNormalServers(List<LocationConfig> servers) {
    return servers
        .where((s) => s.serverType.toLowerCase() != 'smart')
        .toList();
  }
}
