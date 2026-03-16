class AppConstants {

  // ══════════════════════════════════════════════════════════
  // ✅ 1. BACKEND URL  →  Line 9 & 10
  // ══════════════════════════════════════════════════════════
  // FIX: Updated from dead worf.replit.dev dev URL to deployed production URL
  // The backend Node.js API runs at /api/v1 on the deployed Replit app
  static const String baseUrl = 'https://web-production-e6c90c.up.railway.app/api/v1'; // ← LINE 9
  static const String wsUrl   = 'wss://web-production-e6c90c.up.railway.app';           // ← LINE 10

  // ══════════════════════════════════════════════════════════
  // ✅ 2. GOOGLE MAPS KEY  →  Line 17
  // ══════════════════════════════════════════════════════════
  static const String googleMapsKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // ← LINE 17

  // ══════════════════════════════════════════════════════════
  // ✅ 3. CASHFREE KEYS  →  Line 24-25
  //    https://merchant.cashfree.com → Developers → API Keys
  // ══════════════════════════════════════════════════════════
  static const String cashfreeAppId     = '';      // ← LINE 24
  static const String cashfreeSecretKey = '';// ← LINE 25

  // ══════════════════════════════════════════════════════════
  // ✅ 4. GEMINI / OPENAI KEY  →  Line 29
  //    https://aistudio.google.com/app/apikey
  // ══════════════════════════════════════════════════════════
  static const String geminiKey = 'AIzaSyC0hmuQibdcPsQStTyofhhHw86HWs4ZD7k'; // ← LINE 29

  // ══════════════════════════════════════════════════════════
  // ✅ 5. ADMOB IDs  →  Lines 34-50
  //    https://admob.google.com → Apps → Add App
  //    Real IDs milne tak neeche TEST IDs use honge automatically
  // ══════════════════════════════════════════════════════════
  static const String admobAppId            = 'ca-app-pub-4009424857724121~5782436256';           // ← LINE 34
  static const String admobBannerHome       = 'ca-app-pub-4009424857724121/4864581615';   // ← LINE 35
  static const String admobBannerMechanic   = 'ca-app-pub-4009424857724121/4864581615';   // ← LINE 36
  static const String admobInterstitialId   = 'ca-app-pub-4009424857724121/6261423767';  // ← LINE 37
  static const String admobRewardedId       = 'ca-app-pub-4009424857724121/2797326054';      // ← LINE 38

  // Google Test IDs — jab tak real IDs na daalo yeh use honge
  static const String _testBanner       = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded     = 'ca-app-pub-3940256099942544/5224354917';

  // Yeh methods use karo code mein — test/live automatically switch hoga
  static bool get useTestAds => admobBannerHome.startsWith('YOUR_');
  static String get bannerHomeId      => useTestAds ? _testBanner       : admobBannerHome;
  static String get bannerMechanicId  => useTestAds ? _testBanner       : admobBannerMechanic;
  static String get interstitialId    => useTestAds ? _testInterstitial : admobInterstitialId;
  static String get rewardedId        => useTestAds ? _testRewarded     : admobRewardedId;

  // App
  static const String appName       = 'Raahi';
  static const String appVersion    = '1.0.0';
  static const String supportPhone  = '18001234567';

  // P2P
  static const double defaultSearchRadius       = 10.0; // km
  static const int    jobAcceptTimeoutSeconds   = 30;
  static const int    locationUpdateIntervalSeconds = 15;

  // Commission
  static const double platformCommission = 0.15; // 15%

  // Subscription Prices
  static const double basicPlanPrice = 999.0;
  static const double proPlanPrice   = 2499.0;
}
