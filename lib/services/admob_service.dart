// lib/services/admob_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../controllers/settings_controller.dart';

/// جایگاه‌های تبلیغ در اپ
enum AdSlot {
  splashOpen,
  connectInterstitial,
  connectRewardInterstitial,
  disconnectInterstitial,
  disconnectRewardInterstitial,
  rewarded,
  rewardInterstitial,
}

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  final Map<AdSlot, InterstitialAd?> _intAds    = {};
  final Map<AdSlot, RewardedAd?> _rewAds        = {};
  final Map<AdSlot, RewardedInterstitialAd?> _rewIntAds = {};
  final Map<AdSlot, bool> _isReady = {for (var s in AdSlot.values) s: false};

  bool _sdkInitialised = false;

  /// فراخوانی در main.dart **بعد از** بارگذاری تنظیمات
  Future<void> init() async {
    if (_sdkInitialised) return;

    await MobileAds.instance.initialize();
    _sdkInitialised = true;

    // پیش‌بارگذاری همه‌ی اسلات‌ها
    for (final slot in AdSlot.values) {
      unawaited(_loadAd(slot));
    }
  }

  String? _unitId(AdSlot slot) {
    // مپ m از SettingsController.instance.settings.adUnits می‌آید
    // که در آن کلیدها به صورت رشته‌ای ساده مثل 'splashOpen', 'connectInterstitial' و غیره هستند
    // (این کلیدها از فایل settings_controller.dart -> AppSettings.fromJson می‌آیند)
    final m = SettingsController.instance.settings.adUnits;
    switch (slot) {
      case AdSlot.splashOpen:
        return m['splashOpen']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.connectInterstitial:
        return m['connectInterstitial']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.connectRewardInterstitial:
        return m['connectRewardInterstitial']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.disconnectInterstitial:
        return m['disconnectInterstitial']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.disconnectRewardInterstitial:
        return m['disconnectRewardInterstitial']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.rewardInterstitial:
        return m['rewardInterstitial']; // ✅ کلید اصلاح شده و صحیح
      case AdSlot.rewarded:
        return m['rewarded']; // ✅ کلید اصلاح شده و صحیح (این مورد از قبل هم درست بود)
    }
    // اگر به هر دلیلی هیچکدام از case ها مچ نشد (که نباید اتفاق بیفتد برای enum)
    // می‌توانید null برگردانید یا یک لاگ خطا ثبت کنید.
    // return null;
  }

  Future<void> _loadAd(AdSlot slot) async {
    final unitId = _unitId(slot);
    if (unitId == null || unitId.isEmpty) {
      debugPrint('⚠️ No Ad Unit ID for slot $slot – skipping');
      _isReady[slot] = false;
      return;
    }
    debugPrint('🔄 Loading ad for $slot (unitId=$unitId)');

    switch (slot) {
      case AdSlot.splashOpen:
      case AdSlot.connectInterstitial:
      case AdSlot.disconnectInterstitial:
        if (_intAds[slot] != null) return;
        await InterstitialAd.load(
          adUnitId: unitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _intAds[slot] = ad;
              _isReady[slot] = true;
              debugPrint('✅ Interstitial loaded for $slot');
            },
            onAdFailedToLoad: (error) {
              _intAds[slot] = null;
              _isReady[slot] = false;
              debugPrint('❌ Interstitial failed for $slot: $error');
            },
          ),
        );
        break;

      case AdSlot.connectRewardInterstitial:
      case AdSlot.disconnectRewardInterstitial:
      case AdSlot.rewardInterstitial:
        if (_rewIntAds[slot] != null) return;
        await RewardedInterstitialAd.load(
          adUnitId: unitId,
          request: const AdRequest(),
          rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _rewIntAds[slot] = ad;
              _isReady[slot] = true;
              debugPrint('✅ RewardedInterstitial loaded for $slot');
            },
            onAdFailedToLoad: (error) {
              _rewIntAds[slot] = null;
              _isReady[slot] = false;
              debugPrint('❌ RewardedInterstitial failed for $slot: $error');
            },
          ),
        );
        break;

      case AdSlot.rewarded:
        if (_rewAds[slot] != null) return;
        await RewardedAd.load(
          adUnitId: unitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _rewAds[slot] = ad;
              _isReady[slot] = true;
              debugPrint('✅ Rewarded loaded for $slot');
            },
            onAdFailedToLoad: (error) {
              _rewAds[slot] = null;
              _isReady[slot] = false;
              debugPrint('❌ Rewarded failed for $slot: $error');
            },
          ),
        );
        break;
    }
  }

  Future<void> _showAd(AdSlot slot) async {
    if (_isReady[slot] != true) {
      debugPrint('⚠️ Ad not ready for $slot, reloading...');
      unawaited(_loadAd(slot));
      return;
    }

    switch (slot) {
      case AdSlot.splashOpen:
      case AdSlot.connectInterstitial:
      case AdSlot.disconnectInterstitial:
        final ad = _intAds[slot];
        if (ad == null) return;
        final c = Completer<void>();
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (a) {
            a.dispose();
            _intAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            c.complete();
          },
          onAdFailedToShowFullScreenContent: (a, error) {
            a.dispose();
            _intAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            debugPrint('❌ Show failed for $slot: $error');
            c.complete();
          },
        );
        ad.show();
        await c.future;
        break;

      case AdSlot.connectRewardInterstitial:
      case AdSlot.disconnectRewardInterstitial:
      case AdSlot.rewardInterstitial:
        final ad = _rewIntAds[slot];
        if (ad == null) return;
        final c2 = Completer<void>();
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (a) {
            a.dispose();
            _rewIntAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            c2.complete();
          },
          onAdFailedToShowFullScreenContent: (a, error) {
            a.dispose();
            _rewIntAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            debugPrint('❌ Show failed for $slot: $error');
            c2.complete();
          },
        );
        ad.show(onUserEarnedReward: (_, __) {});
        await c2.future;
        break;

      case AdSlot.rewarded:
        final ad = _rewAds[slot];
        if (ad == null) return;
        final c3 = Completer<void>();
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (a) {
            a.dispose();
            _rewAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            c3.complete();
          },
          onAdFailedToShowFullScreenContent: (a, error) {
            a.dispose();
            _rewAds[slot] = null; _isReady[slot] = false;
            unawaited(_loadAd(slot));
            debugPrint('❌ Show failed for $slot: $error');
            c3.complete();
          },
        );
        ad.show(onUserEarnedReward: (_, __) {});
        await c3.future;
        break;
    }
  }

  Future<void> showConnectAd() async {
    final s = SettingsController.instance.settings;
    if (!s.showAds) return;
    // فرض می‌کنیم کلیدهای adIntervalEnabled در settings_controller.dart با فرمت 'slotName' هستند.
    // اگر فرمت دیگری دارند (مثلاً 'reward_interstitial_connect_enabled')، باید اینجا هم اصلاح شوند.
    // اما با توجه به کد settings_controller.dart، به نظر می‌رسد کلیدها باید نام اسلات باشند.
    // با این حال، JSON شما کلیدهایی مثل 'unityads_reward_interstitial_connect_interval_enabled' دارد.
    // پس باید در settings_controller.dart -> AppSettings.fromJson، مپ adIntervalEnabled هم با کلیدهای ساده پر شود.
    // فعلا فرض می‌کنیم که کلیدها در s.adIntervalEnabled ساده هستند (مانند 'connectRewardInterstitial')
    // اگر اینطور نیست، باید آن بخش از settings_controller.dart را هم اصلاح کنید.
    // در حال حاضر، با توجه به کد ارسالی settings_controller.dart، کلیدها به صورت 'unityads_..._interval_enabled' هستند.
    // پس برای هماهنگی، باید یا اینجا از همان کلیدها استفاده کنید یا در settings_controller.dart کلیدها را ساده کنید.

    // برای مثال، اگر در settings_controller.dart کلیدها به صورت زیر تعریف شده باشند:
    // final adIntervalEnabled = <String, bool>{
    //   'connectRewardInterstitial': json['unityads_reward_interstitial_connect_interval_enabled'] as bool? ?? false,
    //   'connectInterstitial':    json['unityads_interstitial_connect_interval_enabled']           as bool? ?? false,
    // };
    // آنگاه کد زیر صحیح خواهد بود:

    if (s.adIntervalEnabled['connectRewardInterstitial'] == true) { // یا کلید دقیق از JSON اگر هنوز `unityads_...` است
      await _showAd(AdSlot.connectRewardInterstitial);
    } else if (s.adIntervalEnabled['connectInterstitial'] == true) { // یا کلید دقیق از JSON
      await _showAd(AdSlot.connectInterstitial);
    }
  }

  Future<void> showDisconnectAd() async {
    final s = SettingsController.instance.settings;
    if (!s.showAds) return;
    // مشابه کامنت بالا برای showConnectAd
    if (s.adIntervalEnabled['disconnectRewardInterstitial'] == true) { // یا کلید دقیق از JSON
      await _showAd(AdSlot.disconnectRewardInterstitial);
    } else if (s.adIntervalEnabled['disconnectInterstitial'] == true) { // یا کلید دقیق از JSON
      await _showAd(AdSlot.disconnectInterstitial);
    }
  }

  Future<void> showSplashAd() async {
    final s = SettingsController.instance.settings;
    if (!s.showAds) return;
    // برای splashAd، معمولا interval enabled خاصی وجود ندارد، اما اگر دارید، مشابه بالا بررسی کنید.
    await _showAd(AdSlot.splashOpen);
  }

  void dispose() {
    for (final ad in _intAds.values)    ad?.dispose();
    for (final ad in _rewAds.values)    ad?.dispose();
    for (final ad in _rewIntAds.values) ad?.dispose();
    _intAds.clear(); _rewAds.clear(); _rewIntAds.clear();
    _isReady.clear(); // این خط اضافه شد تا _isReady هم پاک شود.
  }
}