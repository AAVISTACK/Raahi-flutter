// ============================================================
// lib/services/ad_service.dart
// AdMob — Banner, Interstitial, Rewarded
// Smart placement — driver experience destroy nahi hoga
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/constants.dart';

class AdService {
  static final AdService _i = AdService._();
  factory AdService() => _i;
  AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _appOpenCount = 0;

  // ── Initialize AdMob ──────────────────────────────────────
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ── Preload Interstitial ──────────────────────────────────
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  // Show interstitial — sirf job complete hone pe
  void showInterstitialAfterJobComplete() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial(); // preload next
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // Show interstitial — app open pe (sirf har 3rd open pe)
  void showInterstitialOnAppOpen() {
    _appOpenCount++;
    if (_appOpenCount % 3 != 0) return; // har 3rd open pe
    showInterstitialAfterJobComplete();
  }

  // ── Preload Rewarded ──────────────────────────────────────
  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  // Show rewarded — AI extra messages ke liye
  // onRewarded callback mein extra messages unlock karo
  void showRewardedForAiMessages({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) {
    if (_rewardedAd == null) {
      onFailed();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded(); // preload next
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
    _rewardedAd = null;
  }

  bool get isRewardedReady => _rewardedAd != null;
}
