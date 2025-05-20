// lib/services/ad_service.dart

import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool wasCancelled = false;

  /// Loads and shows an interstitial ad, tracking if it was cancelled.
  static Future<void> showInterstitialAd({required String adUnitId}) async {
    wasCancelled = false;
    final completer = Completer<void>();
    InterstitialAd? interstitial;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitial = ad;
          ad.setImmersiveMode(true);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              wasCancelled = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              wasCancelled = true;
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Treat load failure as a cancellation path
          wasCancelled = true;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
