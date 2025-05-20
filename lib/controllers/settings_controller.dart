import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;    // ← اضافه شد
import '../models/app_settings.dart';
import '../services/app_settings_api.dart';

/// Singleton برای مدیریت و دسترسی به تنظیمات اپ
class SettingsController {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  /// مقداردهی می‌شود پس از فراخوانی load()
  late AppSettings settings;

  /// بارگذاری تنظیمات از سرور
  Future<void> load() async {
    try {
      settings = await AppSettingsApi.fetchSettings();
      debugPrint('>>> Loaded AppSettings: $settings');
      debugPrint('    includeEnabled: ${settings.includeEnabled}');
      debugPrint('    smartModeEnabled: ${settings.smartModeEnabled}');
      debugPrint('    includeTimezones: ${settings.includeTimezones}');
    } catch (e, st) {
      debugPrint('Error loading AppSettings: $e\n$st');
      // در صورت خطا یک نمونه‌ی پیش‌فرض بسازید
      settings = AppSettings.fromJson({
        'exclude_timezones': <String>[],
        'include_timezones': <String>[],
        'include_enabled': false,
        'exclude_enabled': false,
        'privacy_policy_link': '',
        'app_version': '',
        'auto_connect_enabled': false,
        'prevent_old_versions': false,
        'globally_disable_vpn': false,
        'show_vpn_iran': false,
        'show_vpn_outside_iran': false,
        'update_filter_enabled': false,
        'connection_limit_hours': null,
        'connection_limit_minutes': null,
        'delay_before_connect': null,
        'delay_before_disconnect': null,
        'delay_before_splash_smc': null,
        'delay_before_splash_smd': null,
        'splash_smc_ping_enabled': false,
        'splash_smc_request_time': null,
        'splash_smd_ping_enabled': false,
        'splash_smd_request_time': null,
        'normal_int_c_ping_enabled': false,
        'normal_int_c_request_time': null,
        'normal_int_d_ping_enabled': false,
        'normal_int_d_request_time': null,
        'ping_after_connection_enabled': false,
        'smart_mode_enabled': false,
        'show_admob_ads': false,
        'gdpr_active': false,
        'unityads_reward_open_id': '',
        'unityads_interstitial_connect_id': '',
        'unityads_reward_interstitial_connect_id': '',
        'unityads_interstitial_disconnect_id': '',
        'unityads_reward_interstitial_disconnect_id': '',
        'unityads_interstitial_id': '',
        'unityads_rewarded_id': '',
        // … سایر کلیدهای مورد نیاز براساس AppSettings.fromJson …
      });
    }
  }

  /// آیا Smart-mode از سرور فعال شده؟
  bool get smartModeEnabled => settings.smartModeEnabled;

  /// آیا include_mode از سرور فعال است؟
  bool get includeEnabled => settings.includeEnabled;

  /// لیست کدهای کشور برای Smart
  List<String> get includeTimezones => settings.includeTimezones;

  /// تشخیص کد کشور واقعی (اول IP-geo، بعد locale)
  Future<String> detectUserCountryCode() async {
    // ۱. IP-geo
    try {
      debugPrint('DetectCountry: falling back to IP lookup…');
      final resp = await http.get(Uri.parse('http://ip-api.com/json'));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final country = body['countryCode'] as String?;
        if (country != null && country.isNotEmpty) {
          debugPrint('DetectCountry: via IP = $country');
          return country.toLowerCase();
        }
        debugPrint('DetectCountry: IP lookup returned no countryCode');
      } else {
        debugPrint('DetectCountry: IP lookup status ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('DetectCountry: IP-geo lookup failed: $e');
    }

    // ۲. locale
    final localeCode = WidgetsBinding.instance.window.locale.countryCode;
    debugPrint('DetectCountry: locale = $localeCode');
    return (localeCode ?? '').toLowerCase();
  }

  /// آیا کاربر در یکی از کشورهای include شده است؟
  bool isSmartCountry(String countryCode) {
    if (!smartModeEnabled || !includeEnabled) return false;
    final code = countryCode.toLowerCase();
    final ok = includeTimezones.map((c) => c.toLowerCase()).contains(code);
    debugPrint('isSmartCountry($code) → $ok '
        '(smartMode=$smartModeEnabled, includeEnabled=$includeEnabled, list=$includeTimezones)');
    return ok;
  }
}
