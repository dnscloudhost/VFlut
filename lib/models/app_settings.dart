// lib/models/app_settings.dart

import '../services/admob_service.dart';

/// نگه داشتن تمام کلیدهای خروجی API
class AppSettings {
  // ناحیه/کشور
  final List<String> excludeTimezones;
  final List<String> includeTimezones;
  final bool includeEnabled;
  final bool excludeEnabled;

  // لینک‌ها و نسخه
  final String privacyPolicyLink;
  final String appVersion;

  // ویژگی‌های عمومی
  final bool autoConnectEnabled;
  final bool preventOldVersions;
  final bool globallyDisableVpn;
  final bool showVpnIran;
  final bool showVpnOutsideIran;
  final bool updateFilterEnabled;

  // محدودیت اتصال
  final int? connectionLimitHours;
  final int? connectionLimitMinutes;

  // تأخیرها
  final int? delayBeforeConnect;
  final int? delayBeforeDisconnect;
  final int? delayBeforeSplashSmc;
  final int? delayBeforeSplashSmd;

  // پینگ‌ها
  final bool splashSmcPingEnabled;
  final int?  splashSmcRequestTime;
  final bool splashSmdPingEnabled;
  final int?  splashSmdRequestTime;
  final bool normalIntCPingEnabled;
  final int?  normalIntCRequestTime;
  final bool normalIntDPingEnabled;
  final int?  normalIntDRequestTime;
  final bool pingAfterConnectionEnabled;

  // AdMob / Unity
  final bool smartModeEnabled;   // ← فیلد جدید
  final bool showAdmobAds;
  final bool gdprActive;
  final Map<String, String> adUnits;          // همهٔ id‌ها، کلید = نام اسلات
  final Map<String, dynamic> adIntervals;     // همهٔ مقادیر interval
  final Map<String, bool>  adIntervalEnabled; // فعال/غیرفعال

  AppSettings({
    required this.excludeTimezones,
    required this.includeTimezones,
    required this.includeEnabled,
    required this.excludeEnabled,
    required this.privacyPolicyLink,
    required this.appVersion,
    required this.autoConnectEnabled,
    required this.preventOldVersions,
    required this.globallyDisableVpn,
    required this.showVpnIran,
    required this.showVpnOutsideIran,
    required this.updateFilterEnabled,
    required this.connectionLimitHours,
    required this.connectionLimitMinutes,
    required this.delayBeforeConnect,
    required this.delayBeforeDisconnect,
    required this.delayBeforeSplashSmc,
    required this.delayBeforeSplashSmd,
    required this.splashSmcPingEnabled,
    required this.splashSmcRequestTime,
    required this.splashSmdPingEnabled,
    required this.splashSmdRequestTime,
    required this.normalIntCPingEnabled,
    required this.normalIntCRequestTime,
    required this.normalIntDPingEnabled,
    required this.normalIntDRequestTime,
    required this.pingAfterConnectionEnabled,
    required this.smartModeEnabled,            // ← اضافه شد
    required this.showAdmobAds,
    required this.gdprActive,
    required this.adUnits,
    required this.adIntervals,
    required this.adIntervalEnabled,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    // استخراج تمام کلیدهای ..._interval و ..._interval_enabled
    Map<String, dynamic> _extract(String pattern) =>
        Map.fromEntries(j.entries.where((e) => RegExp(pattern).hasMatch(e.key)));

    // نگاشت صریح Ad Unit ها به اسلات‌هایی که AdMobService انتظار دارد
    final units = <String, String>{
      AdSlot.splashOpen.name                  : j['unityads_reward_open_id']                    as String? ?? '',
      AdSlot.connectInterstitial.name         : j['unityads_interstitial_connect_id']           as String? ?? '',
      AdSlot.connectRewardInterstitial.name   : j['unityads_reward_interstitial_connect_id']    as String? ?? '',
      AdSlot.disconnectInterstitial.name      : j['unityads_interstitial_disconnect_id']        as String? ?? '',
      AdSlot.disconnectRewardInterstitial.name: j['unityads_reward_interstitial_disconnect_id'] as String? ?? '',
      AdSlot.rewardInterstitial.name          : j['unityads_reward_interstitial_id']            as String? ?? '',
      AdSlot.rewarded.name                    : j['unityads_rewarded_id']                       as String? ?? '',
    };

    final intervals = _extract(r'_interval$');
    final intervalsEnabled = _extract(r'_interval_enabled$')
        .map((k, v) => MapEntry(k, v as bool));

    return AppSettings(
      excludeTimezones:             (j['exclude_timezones'] as List<dynamic>).cast<String>(),
      includeTimezones:             (j['include_timezones'] as List<dynamic>).cast<String>(),
      includeEnabled:               j['include_enabled']                as bool,
      excludeEnabled:               j['exclude_enabled']                as bool,
      privacyPolicyLink:            j['privacy_policy_link']            as String?  ?? '',
      appVersion:                   j['app_version']                    as String?  ?? '',
      autoConnectEnabled:           j['auto_connect_enabled']           as bool,
      preventOldVersions:           j['prevent_old_versions']           as bool,
      globallyDisableVpn:           j['globally_disable_vpn']           as bool,
      showVpnIran:                  j['show_vpn_iran']                  as bool,
      showVpnOutsideIran:           j['show_vpn_outside_iran']          as bool,
      updateFilterEnabled:          j['update_filter_enabled']          as bool,
      connectionLimitHours:         j['connection_limit_hours']         as int?,
      connectionLimitMinutes:       j['connection_limit_minutes']       as int?,
      delayBeforeConnect:           j['delay_before_connect']           as int?,
      delayBeforeDisconnect:        j['delay_before_disconnect']        as int?,
      delayBeforeSplashSmc:         j['delay_before_splash_smc']        as int?,
      delayBeforeSplashSmd:         j['delay_before_splash_smd']        as int?,
      splashSmcPingEnabled:         j['splash_smc_ping_enabled']        as bool,
      splashSmcRequestTime:         j['splash_smc_request_time']        as int?,
      splashSmdPingEnabled:         j['splash_smd_ping_enabled']        as bool,
      splashSmdRequestTime:         j['splash_smd_request_time']        as int?,
      normalIntCPingEnabled:        j['normal_int_c_ping_enabled']      as bool,
      normalIntCRequestTime:        j['normal_int_c_request_time']      as int?,
      normalIntDPingEnabled:        j['normal_int_d_ping_enabled']      as bool,
      normalIntDRequestTime:        j['normal_int_d_request_time']      as int?,
      pingAfterConnectionEnabled:   j['ping_after_connection_enabled']  as bool,
      smartModeEnabled:             j['smart_mode_enabled']             as bool? ?? false, // ← نگاشت JSON
      showAdmobAds:                 j['show_admob_ads']                 as bool,
      gdprActive:                   j['gdpr_active']                    as bool,
      adUnits:                      units,
      adIntervals:                  intervals,
      adIntervalEnabled:            intervalsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'exclude_timezones': excludeTimezones,
    'include_timezones': includeTimezones,
    'include_enabled': includeEnabled,
    'exclude_enabled': excludeEnabled,
    'privacy_policy_link': privacyPolicyLink,
    'app_version': appVersion,
    'auto_connect_enabled': autoConnectEnabled,
    'prevent_old_versions': preventOldVersions,
    'globally_disable_vpn': globallyDisableVpn,
    'show_vpn_iran': showVpnIran,
    'show_vpn_outside_iran': showVpnOutsideIran,
    'update_filter_enabled': updateFilterEnabled,
    'connection_limit_hours': connectionLimitHours,
    'connection_limit_minutes': connectionLimitMinutes,
    'delay_before_connect': delayBeforeConnect,
    'delay_before_disconnect': delayBeforeDisconnect,
    'delay_before_splash_smc': delayBeforeSplashSmc,
    'delay_before_splash_smd': delayBeforeSplashSmd,
    'splash_smc_ping_enabled': splashSmcPingEnabled,
    'splash_smc_request_time': splashSmcRequestTime,
    'splash_smd_ping_enabled': splashSmdPingEnabled,
    'splash_smd_request_time': splashSmdRequestTime,
    'normal_int_c_ping_enabled': normalIntCPingEnabled,
    'normal_int_c_request_time': normalIntCRequestTime,
    'normal_int_d_ping_enabled': normalIntDPingEnabled,
    'normal_int_d_request_time': normalIntDRequestTime,
    'ping_after_connection_enabled': pingAfterConnectionEnabled,
    'smart_mode_enabled': smartModeEnabled,    // ← نگاشت خروجی
    'show_admob_ads': showAdmobAds,
    'gdpr_active': gdprActive,
    // برای adUnits و intervals طبق نیاز خروجی را کامل کنید
  };
}
