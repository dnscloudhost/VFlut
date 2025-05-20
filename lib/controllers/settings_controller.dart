// lib/controllers/settings_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    } catch (e, st) {
      debugPrint('Error loading AppSettings: $e\n$st');
      // در صورت خطا یک نمونه‌ی پیش‌فرض خالی بسازید
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
        'smart_mode_enabled': false,          // ← اضافه شد
        'show_admob_ads': false,
        'gdpr_active': false,
        'unityads_reward_open_id': '',
        'unityads_interstitial_connect_id': '',
        'unityads_reward_interstitial_connect_id': '',
        'unityads_interstitial_disconnect_id': '',
        'unityads_reward_interstitial_disconnect_id': '',
        'unityads_interstitial_id': '',
        'unityads_rewarded_id': '',
        'unityads_reward_open_interval_enabled': false,
        'unityads_interstitial_connect_interval_enabled': false,
        'unityads_reward_interstitial_connect_interval_enabled': false,
        'unityads_interstitial_disconnect_interval_enabled': false,
        'unityads_reward_interstitial_disconnect_interval_enabled': false,
        'unityads_reward_interstitial_interval_enabled': false,
        'unityads_rewarded_interval_enabled': false,
      });
    }
  }

  /// آیا قابلیت Smart VPN آزاد است؟
  bool get smartModeEnabled => settings.smartModeEnabled;

  /// بررسی اینکه آیا یک کشور Smart تعریف شده
  bool isSmartCountry(String countryCode) {
    // فقط وقتی Smart Mode فعال است و includeEnabled را داریم
    if (!settings.smartModeEnabled || !settings.includeEnabled) return false;
    final code = countryCode.toLowerCase();
    return settings.includeTimezones
        .map((c) => c.toLowerCase())
        .contains(code);
  }

  /// تشخیص خودکار کد کشور دستگاه
  Future<String> detectUserCountryCode() async {
    final locale = WidgetsBinding.instance.window.locale;
    return locale.countryCode?.toLowerCase() ?? '';
  }
}
