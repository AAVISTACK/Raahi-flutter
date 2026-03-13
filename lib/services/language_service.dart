// ============================================================
// FILE 2: lib/services/language_service.dart  (NEW)
// ============================================================
// Handles: save/load language preference, TTS/STT locale,
//          and notifies listeners on language change.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LanguageService extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _prefKey = 'app_language';

  AppLanguage _currentLanguage = AppLanguage.english; // default

  AppLanguage get currentLanguage => _currentLanguage;
  String get currentCode => _currentLanguage.code;
  String get currentLocale => _currentLanguage.localeCode;

  // ── Load from SharedPreferences on app start ───────────
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'hi';
    _currentLanguage = AppLanguageExt.fromCode(saved);
    notifyListeners();
  }

  // ── Save & apply new language ──────────────────────────
  Future<void> setLanguage(AppLanguage lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.code);
    notifyListeners(); // Rebuilds all listening widgets
  }

  // ── Translate a UI key ─────────────────────────────────
  String t(String key) => TranslationMap.get(key, _currentLanguage);

  // ── All supported languages (for the switcher UI) ──────
  static const List<AppLanguage> supported = [
    AppLanguage.hindi,
    AppLanguage.english,
    AppLanguage.punjabi,
    AppLanguage.tamil,
    AppLanguage.telugu,
    AppLanguage.bengali,
  ];
}

// ============================================================
// TranslationMap — All UI strings for every language
// ============================================================
class TranslationMap {
  // Key → { langCode → translated string }
  static const Map<String, Map<String, String>> _map = {

    // ── App general ──────────────────────────────────────
    'app_name': {
      'en': 'Raahi',
      'hi': 'राही',
      'pa': 'ਰਾਹੀ',
      'ta': 'ராஹி',
      'te': 'రాహి',
      'bn': 'রাহি',
    },

    // ── Home Screen ──────────────────────────────────────
    'greeting': {
      'en': 'Welcome, Brother! 🙏',
      'hi': 'नमस्ते, भाई! 🙏',
      'pa': 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ, ਭਾਈ! 🙏',
      'ta': 'வணக்கம், அண்ணா! 🙏',
      'te': 'నమస్కారం, అన్నా! 🙏',
      'bn': 'নমস্কার, ভাই! 🙏',
    },
    'available_on': {
      'en': 'You are Available — Ready to Help',
      'hi': 'आप Available हैं — Help के लिए Ready',
      'pa': 'ਤੁਸੀਂ ਉਪਲਬਧ ਹੋ — ਮਦਦ ਲਈ ਤਿਆਰ',
      'ta': 'நீங்கள் கிடைக்கிறீர்கள் — உதவ தயார்',
      'te': 'మీరు అందుబాటులో ఉన్నారు — సహాయానికి సిద్ధం',
      'bn': 'আপনি উপলব্ধ — সাহায্যের জন্য প্রস্তুত',
    },
    'available_off': {
      'en': 'Offline — No notifications',
      'hi': 'Offline — कोई Notify नहीं होगा',
      'pa': 'ਆਫਲਾਈਨ — ਕੋਈ ਸੂਚਨਾ ਨਹੀਂ',
      'ta': 'ஆஃப்லைன் — அறிவிப்பு இல்லை',
      'te': 'ఆఫ్‌లైన్ — నోటిఫికేషన్ లేదు',
      'bn': 'অফলাইন — কোনো নোটিফিকেশন নেই',
    },

    // ── SOS ──────────────────────────────────────────────
    'sos_title': {
      'en': 'SOS — Emergency',
      'hi': 'SOS — Emergency',
      'pa': 'SOS — ਐਮਰਜੈਂਸੀ',
      'ta': 'SOS — அவசரநிலை',
      'te': 'SOS — అత్యవసర పరిస్థితి',
      'bn': 'SOS — জরুরি অবস্থা',
    },
    'sos_sub': {
      'en': 'Press for instant help',
      'hi': 'Press करके turant madad pao',
      'pa': 'ਤੁਰੰਤ ਮਦਦ ਲਈ ਦਬਾਓ',
      'ta': 'உடனடி உதவிக்கு அழுத்துங்கள்',
      'te': 'తక్షణ సహాయం కోసం నొక్కండి',
      'bn': 'তাৎক্ষণিক সাহায্যের জন্য চাপুন',
    },

    // ── Action Cards ─────────────────────────────────────
    'request_help': {
      'en': 'Request Help',
      'hi': 'Madad Maango',
      'pa': 'ਮਦਦ ਮੰਗੋ',
      'ta': 'உதவி கேளுங்கள்',
      'te': 'సహాయం అడగండి',
      'bn': 'সাহায্য চাও',
    },
    'find_mechanic': {
      'en': 'Find Mechanic',
      'hi': 'Mechanic Dhundo',
      'pa': 'ਮਕੈਨਿਕ ਲੱਭੋ',
      'ta': 'மெக்கானிக் தேடுங்கள்',
      'te': 'మెకానిక్ వెతకండి',
      'bn': 'মেকানিক খুঁজুন',
    },
    'ai_assistant': {
      'en': 'AI Assistant',
      'hi': 'AI Sahayak',
      'pa': 'AI ਸਹਾਇਕ',
      'ta': 'AI உதவியாளர்',
      'te': 'AI సహాయకుడు',
      'bn': 'AI সহায়ক',
    },
    'my_jobs': {
      'en': 'My Jobs',
      'hi': 'Mere Jobs',
      'pa': 'ਮੇਰੀਆਂ ਨੌਕਰੀਆਂ',
      'ta': 'என் வேலைகள்',
      'te': 'నా జాబ్స్',
      'bn': 'আমার কাজ',
    },

    // ── Buttons ──────────────────────────────────────────
    'btn_send_otp': {
      'en': 'Send OTP 📱',
      'hi': 'OTP Bhejo 📱',
      'pa': 'OTP ਭੇਜੋ 📱',
      'ta': 'OTP அனுப்பு 📱',
      'te': 'OTP పంపండి 📱',
      'bn': 'OTP পাঠান 📱',
    },
    'btn_verify': {
      'en': 'Verify ✓',
      'hi': 'Verify Karo ✓',
      'pa': 'ਤਸਦੀਕ ਕਰੋ ✓',
      'ta': 'சரிபார்க்கவும் ✓',
      'te': 'ధృవీకరించండి ✓',
      'bn': 'যাচাই করুন ✓',
    },
    'btn_get_help': {
      'en': 'Notify Nearby Drivers!',
      'hi': 'Nearby Drivers Ko Notify Karo!',
      'pa': 'ਨੇੜੇ ਡਰਾਈਵਰਾਂ ਨੂੰ ਸੂਚਿਤ ਕਰੋ!',
      'ta': 'அருகிலுள்ள ஓட்டுநர்களுக்கு அறிவிக்கவும்!',
      'te': 'దగ్గరిలోని డ్రైవర్లకు నోటిఫై చేయండి!',
      'bn': 'কাছের ড্রাইভারদের নোটিফাই করুন!',
    },
    'btn_accept_help': {
      'en': 'Yes, I will Help! 🤝',
      'hi': 'Haan, Help Karunga! 🤝',
      'pa': 'ਹਾਂ, ਮਦਦ ਕਰਾਂਗਾ! 🤝',
      'ta': 'ஆம், உதவுவேன்! 🤝',
      'te': 'అవును, సహాయం చేస్తాను! 🤝',
      'bn': 'হ্যাঁ, সাহায্য করব! 🤝',
    },
    'btn_complete': {
      'en': 'Job Complete ✓',
      'hi': 'Job Complete Hai ✓',
      'pa': 'ਕੰਮ ਮੁਕੰਮਲ ✓',
      'ta': 'வேலை முடிந்தது ✓',
      'te': 'పని పూర్తైంది ✓',
      'bn': 'কাজ সম্পন্ন ✓',
    },
    'btn_register': {
      'en': 'Register! 🔧',
      'hi': 'Register Karo! 🔧',
      'pa': 'ਰਜਿਸਟਰ ਕਰੋ! 🔧',
      'ta': 'பதிவு செய்யுங்கள்! 🔧',
      'te': 'నమోదు చేయండి! 🔧',
      'bn': 'নিবন্ধন করুন! 🔧',
    },

    // ── AI Mechanic screen ────────────────────────────────
    'ai_welcome': {
      'en': 'Hello Brother! 🙏 I am Raahi Bhaiya.\n\nWhat problem is your vehicle having? Tell me — I will guide you step by step.\n\nYou can also use Voice! 🎙️',
      'hi': 'Namaste Bhai! 🙏 Main Raahi Bhaiya hoon.\n\nAapki gaadi mein kya problem aa rahi hai? Bolo, main help karunga — step by step.\n\nVoice se bhi bol sakte ho! 🎙️',
      'pa': 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਭਾਈ! 🙏 ਮੈਂ ਸਹਾਇਕ ਭਾਈਆ ਹਾਂ।\n\nਤੁਹਾਡੀ ਗੱਡੀ ਵਿੱਚ ਕੀ ਸਮੱਸਿਆ ਹੈ? ਦੱਸੋ — ਮੈਂ ਕਦਮ ਦਰ ਕਦਮ ਮਦਦ ਕਰਾਂਗਾ। 🎙️',
      'ta': 'வணக்கம் அண்ணா! 🙏 நான் சஹாயக் பையா.\n\nஉங்கள் வாகனத்தில் என்ன பிரச்சனை? சொல்லுங்கள் — படிப்படியாக வழிகாட்டுவேன். 🎙️',
      'te': 'నమస్కారం అన్నా! 🙏 నేను సహాయక్ భయ్యా.\n\nమీ వాహనంలో ఏమి సమస్య? చెప్పండి — అడుగడుగునా సహాయం చేస్తాను. 🎙️',
      'bn': 'নমস্কার ভাই! 🙏 আমি সহায়ক ভাইয়া।\n\nআপনার গাড়িতে কী সমস্যা? বলুন — ধাপে ধাপে সাহায্য করব। 🎙️',
    },
    'ai_input_hint': {
      'en': 'Type your problem...',
      'hi': 'Problem batao...',
      'pa': 'ਸਮੱਸਿਆ ਦੱਸੋ...',
      'ta': 'பிரச்சனை சொல்லுங்கள்...',
      'te': 'సమస్య చెప్పండి...',
      'bn': 'সমস্যা বলুন...',
    },
    'ai_listening': {
      'en': '🎙️ Listening...',
      'hi': '🎙️ Sun raha hoon...',
      'pa': '🎙️ ਸੁਣ ਰਿਹਾ ਹਾਂ...',
      'ta': '🎙️ கேட்கிறேன்...',
      'te': '🎙️ వింటున్నాను...',
      'bn': '🎙️ শুনছি...',
    },

    // ── Recent Activity ───────────────────────────────────
    'recent_activity': {
      'en': 'Recent Activity',
      'hi': 'Recent Activity',
      'pa': 'ਹਾਲੀਆ ਗਤੀਵਿਧੀ',
      'ta': 'சமீபத்திய செயல்பாடு',
      'te': 'ఇటీవలి కార్యకలాపం',
      'bn': 'সাম্প্রতিক কার্যকলাপ',
    },
    'no_activity': {
      'en': 'No activity yet\nStay available to get job notifications',
      'hi': 'Abhi tak koi activity nahi\nAvailable rehne se jobs milenge',
      'pa': 'ਹਾਲੇ ਕੋਈ ਗਤੀਵਿਧੀ ਨਹੀਂ',
      'ta': 'இதுவரை எந்த செயல்பாடும் இல்லை',
      'te': 'ఇంకా ఏ కార్యకలాపమూ లేదు',
      'bn': 'এখন পর্যন্ত কোনো কার্যকলাপ নেই',
    },


    // ── Login Screen ─────────────────────────────────────
    'welcome_title': {
      'en': 'Welcome\nBack, Bhai! 👋',
      'hi': 'Wapas Aao\nBhai! 👋',
      'pa': 'ਵਾਪਸ ਆਓ\nਭਾਈ! 👋',
      'ta': 'மீண்டும் வருக\nஅண்ணா! 👋',
      'te': 'తిరిగి స్వాగతం\nఅన్నా! 👋',
      'bn': 'ফিরে এলেন\nভাই! 👋',
    },
    'welcome_sub': {
      'en': 'Login with Phone or Google',
      'hi': 'Phone ya Google se login karo',
      'pa': 'ਫੋਨ ਜਾਂ ਗੂਗਲ ਨਾਲ ਲੌਗਿਨ ਕਰੋ',
      'ta': 'போன் அல்லது கூகிள் மூலம் உள்நுழையுங்கள்',
      'te': 'ఫోన్ లేదా గూగుల్ తో లాగిన్ చేయండి',
      'bn': 'ফোন বা গুগল দিয়ে লগিন করুন',
    },
    'mobile_number': {
      'en': 'Mobile Number',
      'hi': 'Mobile Number',
      'pa': 'ਮੋਬਾਈਲ ਨੰਬਰ',
      'ta': 'மொபைல் எண்',
      'te': 'మొబైల్ నంబర్',
      'bn': 'মোবাইল নম্বর',
    },
    'phone_hint': {
      'en': '98765 43210',
      'hi': '98765 43210',
      'pa': '98765 43210',
      'ta': '98765 43210',
      'te': '98765 43210',
      'bn': '98765 43210',
    },
    'or_divider': {
      'en': 'OR',
      'hi': 'YA PHIR',
      'pa': 'ਜਾਂ ਫਿਰ',
      'ta': 'அல்லது',
      'te': 'లేదా',
      'bn': 'অথবা',
    },
    'btn_google_login': {
      'en': 'Continue with Google',
      'hi': 'Google se Login Karo',
      'pa': 'ਗੂਗਲ ਨਾਲ ਜਾਰੀ ਰੱਖੋ',
      'ta': 'கூகிள் மூலம் தொடரவும்',
      'te': 'గూగుల్ తో కొనసాగండి',
      'bn': 'গুগল দিয়ে চালিয়ে যান',
    },
    'mechanic_register_link': {
      'en': 'Are you a Mechanic? Register here →',
      'hi': 'Mechanic ho? Yahan register karo →',
      'pa': 'ਮਕੈਨਿਕ ਹੋ? ਇੱਥੇ ਰਜਿਸਟਰ ਕਰੋ →',
      'ta': 'மெக்கானிக்கா? இங்கே பதிவு செய்யுங்கள் →',
      'te': 'మెకానిక్ అయితే? ఇక్కడ నమోదు చేయండి →',
      'bn': 'মেকানিক? এখানে নিবন্ধন করুন →',
    },
    'terms_note': {
      'en': 'By logging in, you agree to our Terms & Conditions',
      'hi': 'Login karke aap Terms & Conditions se agree karte ho',
      'pa': 'ਲੌਗਿਨ ਕਰਕੇ ਤੁਸੀਂ ਸ਼ਰਤਾਂ ਨਾਲ ਸਹਿਮਤ ਹੋ',
      'ta': 'உள்நுழைவதன் மூலம் நீங்கள் விதிமுறைகளை ஒப்புக்கொள்கிறீர்கள்',
      'te': 'లాగిన్ చేయడం ద్వారా మీరు నిబంధనలకు అంగీకరిస్తున్నారు',
      'bn': 'লগিন করে আপনি শর্তাবলীতে সম্মত হচ্ছেন',
    },
    'invalid_phone': {
      'en': 'Please enter a valid 10-digit number',
      'hi': 'Sahi 10 digit number daalo',
      'pa': 'ਸਹੀ 10 ਅੰਕ ਨੰਬਰ ਦਾਖਲ ਕਰੋ',
      'ta': 'சரியான 10 இலக்க எண் உள்ளிடவும்',
      'te': 'సరైన 10 అంక నంబర్ నమోదు చేయండి',
      'bn': 'সঠিক ১০ সংখ্যার নম্বর দিন',
    },
    'otp_failed': {
      'en': 'OTP failed. Please try again.',
      'hi': 'OTP nahi aaya. Dobara try karo.',
      'pa': 'OTP ਨਹੀਂ ਆਇਆ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।',
      'ta': 'OTP வரவில்லை. மீண்டும் முயற்சிக்கவும்.',
      'te': 'OTP రాలేదు. మళ్ళీ ప్రయత్నించండి.',
      'bn': 'OTP আসেনি। আবার চেষ্টা করুন।',
    },


    'shop': {
      'en': 'Shop',
      'hi': 'Shop',
      'pa': 'ਦੁਕਾਨ',
      'ta': 'கடை',
      'te': 'షాప్',
      'bn': 'দোকান',
    },


    // ── Language Switcher ─────────────────────────────────
    'choose_language': {
      'en': 'Choose Language',
      'hi': 'भाषा चुनें',
      'pa': 'ਭਾਸ਼ਾ ਚੁਣੋ',
      'ta': 'மொழி தேர்ந்தெடுங்கள்',
      'te': 'భాష ఎంచుకోండి',
      'bn': 'ভাষা বেছে নিন',
    },
  };

  /// Get a translated string. Falls back to Hindi then English.
  static String get(String key, AppLanguage lang) {
    final entries = _map[key];
    if (entries == null) return key; // key not found → return key itself
    return entries[lang.code]
        ?? entries['hi']             // fallback to Hindi
        ?? entries['en']             // fallback to English
        ?? key;
  }
}
