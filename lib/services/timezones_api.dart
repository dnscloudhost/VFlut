// lib/services/timezones_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// پاسخ نمونهٔ API:
/// {
///   "include_timezones": [ "ir", "sy", "kp" ],
///   "exclude_timezones": [ "ae", "us", ... ]
/// }
class TimezonesApi {
  static const _endpoint = 'https://YOUR_BACKEND_URL/api/timezones';

  // وقتی null باشد یعنی هنوز فچ نکرده‌ایم
  static Set<String>? _cachedIncludes;
  static Set<String>? _cachedExcludes;

  /// درخواست واقعی به سرور و پر کردن کش
  static Future<void> _fetchAndCache() async {
    final resp = await http.get(Uri.parse(_endpoint));
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch timezones: ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final inc = (body['include_timezones'] as List<dynamic>).cast<String>();
    final exc = (body['exclude_timezones'] as List<dynamic>).cast<String>();

    _cachedIncludes = inc.map((e) => e.toLowerCase()).toSet();
    _cachedExcludes = exc.map((e) => e.toLowerCase()).toSet();
  }

  /// اطمینان از اینکه حتماً یکبار فچ شده‌ایم
  static Future<void> _ensureCache() async {
    if (_cachedIncludes == null || _cachedExcludes == null) {
      await _fetchAndCache();
    }
  }

  /// آیا این ISO2 در لیست Include هست؟
  static Future<bool> isIncluded(String countryIso2) async {
    await _ensureCache();
    return _cachedIncludes!.contains(countryIso2.toLowerCase());
  }

  /// آیا این ISO2 در لیست Exclude هست؟
  static Future<bool> isExcluded(String countryIso2) async {
    await _ensureCache();
    return _cachedExcludes!.contains(countryIso2.toLowerCase());
  }

  /// پاک کردن کش (مثلاً برای رفرش دستی)
  static void clearCache() {
    _cachedIncludes = null;
    _cachedExcludes = null;
  }
}
