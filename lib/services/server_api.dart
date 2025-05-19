// lib/services/server_api.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/locations.dart';

/// سرویس واحد برای:
///  1️⃣ دریافت و دسته‌بندی سرورهای VPN
///  2️⃣ بارگذاری تنظیمات اپ (Ad Units, feature flags, intervals)
class ServerApi {
  // ۱. تنظیمات پایه
  static const _baseUrl = 'https://designed-georgia-banner-threats.trycloudflare.com';
  static const _token    = '26|dhcAmNOaXR2GSsNIkCIt9RsvzFcSkzUPCsAZ8uBRf29385f5';

  // ۲. درخواست شبکه برای سرورها
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

  /// لیست نهایی سرورها = لوکال + ریموت
  static Future<List<LocationConfig>> loadAllServers() async {
    try {
      final remote = await _fetchRemoteServers();
      return [...localConfigs, ...remote];
    } catch (e, st) {
      debugPrint('ServerApi.loadAllServers error: $e\n$st');
      return List<LocationConfig>.from(localConfigs);
    }
  }

  /// برای سازگاری با کدهای قدیمی که loadAll صدا می‌زدند
  static Future<List<LocationConfig>> loadAll() => loadAllServers();

  // ۳. درخواست شبکه برای تنظیمات اپ
  static Future<Map<String, dynamic>> fetchAppSettings() async {
    final uri = Uri.parse('$_baseUrl/api/applications');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $_token',
    });
    if (resp.statusCode != 200) {
      throw Exception('Failed to load app settings: ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    if (list.isEmpty) {
      throw Exception('No app settings returned');
    }
    return list.first as Map<String, dynamic>;
  }

  // ۴. ابزارهای کمکی برای دسته‌بندی سرورها
  static List<LocationConfig> smart(List<LocationConfig> list) =>
      list.where((c) => c.serverType == 'smart').toList();

  static List<LocationConfig> freeAndPro(List<LocationConfig> list) =>
      list.where((c) => c.serverType != 'smart').toList();
}
