// lib/controllers/settings_controller.dart

import 'package:flutter/foundation.dart';
import '../services/server_api.dart';

/// مدل تنظیمات اپلیکیشن
class AppSettings {
  /// نگاشت UnityAds IDs برای هر اسلات
  final Map<String, String> adUnits;
  final bool showAds;
  final Map<String, bool> adIntervalEnabled;

  final int delayBeforeConnect;
  final int delayBeforeDisconnect;
  final int connectionLimitHours;
  final int connectionLimitMinutes;
  final List<String> smartCountries;
  final bool autoConnectEnabled;
  final String privacyPolicyLink;
  final String appVersion;

  AppSettings({
    required this.adUnits,
    required this.showAds,
    required this.adIntervalEnabled,
    required this.delayBeforeConnect,
    required this.delayBeforeDisconnect,
    required this.connectionLimitHours,
    required this.connectionLimitMinutes,
    required this.smartCountries,
    required this.autoConnectEnabled,
    required this.privacyPolicyLink,
    required this.appVersion,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // نگاشت UnityAds IDs
    final adUnits = <String, String>{
      'splashOpen':             json['unityads_reward_open_id']                    as String? ?? '',
      'connectInterstitial':    json['unityads_interstitial_connect_id']           as String? ?? '',
      'connectRewardInterstitial':
      json['unityads_reward_interstitial_connect_id']    as String? ?? '',
      'disconnectInterstitial': json['unityads_interstitial_disconnect_id']       as String? ?? '',
      'disconnectRewardInterstitial':
      json['unityads_reward_interstitial_disconnect_id'] as String? ?? '',
      'rewarded':               json['unityads_rewarded_id']                      as String? ?? '',
      'rewardInterstitial':     json['unityads_reward_interstitial_id']           as String? ?? '',
    };

    // نگاشت Interval Enabled flags
    final adIntervalEnabled = <String, bool>{
      'splashOpen':             json['unityads_reward_open_interval_enabled']                    as bool? ?? false,
      'connectInterstitial':    json['unityads_interstitial_connect_interval_enabled']           as bool? ?? false,
      'connectRewardInterstitial':
      json['unityads_reward_interstitial_connect_interval_enabled']    as bool? ?? false,
      'disconnectInterstitial': json['unityads_interstitial_disconnect_interval_enabled']       as bool? ?? false,
      'disconnectRewardInterstitial':
      json['unityads_reward_interstitial_disconnect_interval_enabled'] as bool? ?? false,
      'rewarded':               json['unityads_rewarded_interval_enabled']                      as bool? ?? false,
      'rewardInterstitial':     json['unityads_reward_interstitial_interval_enabled']           as bool? ?? false,
    };

    return AppSettings(
      adUnits: adUnits,
      showAds:            json['show_admob_ads']           as bool?   ?? false,
      adIntervalEnabled:  adIntervalEnabled,
      delayBeforeConnect: json['delay_before_connect']     as int?    ?? 0,
      delayBeforeDisconnect:
      json['delay_before_disconnect']  as int?    ?? 0,
      connectionLimitHours:
      json['connection_limit_hours']   as int?    ?? 0,
      connectionLimitMinutes:
      json['connection_limit_minutes'] as int?    ?? 0,
      smartCountries:     List<String>.from(json['include_timezones'] as List<dynamic>? ?? []),
      autoConnectEnabled: json['auto_connect_enabled']    as bool?   ?? false,
      privacyPolicyLink:  json['privacy_policy_link']     as String? ?? '',
      appVersion:         json['app_version']             as String? ?? '',
    );
  }
}

/// کنترلر singleton برای مدیریت تنظیمات
class SettingsController {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  AppSettings settings = AppSettings.fromJson({});

  /// بارگذاری تنظیمات از سرور
  Future<void> load() async {
    try {
      final json    = await ServerApi.fetchAppSettings();
      debugPrint('>>> Loaded AppSettings JSON: $json');
      settings      = AppSettings.fromJson(json);
    } catch (e, st) {
      debugPrint('Error loading app settings: $e\n$st');
      // مقادیر قبلی یا پیش‌فرض باقی می‌ماند
    }
  }

  bool isSmartCountry(String countryCode) =>
      settings.smartCountries.contains(countryCode);
}
