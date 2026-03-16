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

      // ── Home Screen — AI Card ─────────────────────────────
      'ai_mechanic_title': {
        'en': 'AI Mechanic',
        'hi': 'AI Mechanic',
        'pa': 'AI ਮਕੈਨਿਕ',
        'ta': 'AI மெக்கானிக்',
        'te': 'AI మెకానిక్',
        'bn': 'AI মেকানিক',
      },
      'ai_mechanic_sub': {
        'en': 'Instant car problem diagnosis',
        'hi': 'Car ki problem turant pehchano',
        'pa': 'ਕਾਰ ਦੀ ਸਮੱਸਿਆ ਤੁਰੰਤ ਪਛਾਣੋ',
        'ta': 'உடனடி கார் பிரச்சனை கண்டறிதல்',
        'te': 'తక్షణ కారు సమస్య నిర్ధారణ',
        'bn': 'তাৎক্ষণিক গাড়ির সমস্যা নির্ণয়',
      },
      'status_online': {
        'en': 'Online',
        'hi': 'Online',
        'pa': 'ਔਨਲਾਈਨ',
        'ta': 'ஆன்லைன்',
        'te': 'ఆన్‌లైన్',
        'bn': 'অনলাইন',
      },
      'voice_input': {
        'en': '🗣️ Voice Input',
        'hi': '🗣️ Voice Input',
        'pa': '🗣️ ਆਵਾਜ਼ ਇਨਪੁਟ',
        'ta': '🗣️ குரல் உள்ளீடு',
        'te': '🗣️ వాయిస్ ఇన్‌పుట్',
        'bn': '🗣️ ভয়েস ইনপুট',
      },
      'six_languages': {
        'en': '🌐 6 Languages',
        'hi': '🌐 6 Bhashayen',
        'pa': '🌐 6 ਭਾਸ਼ਾਵਾਂ',
        'ta': '🌐 6 மொழிகள்',
        'te': '🌐 6 భాషలు',
        'bn': '🌐 ৬ ভাষা',
      },
      'instant': {
        'en': '⚡ Instant',
        'hi': '⚡ Turant',
        'pa': '⚡ ਤੁਰੰਤ',
        'ta': '⚡ உடனடி',
        'te': '⚡ తక్షణం',
        'bn': '⚡ তাৎক্ষণিক',
      },
      'free': {
        'en': '🆓 Free',
        'hi': '🆓 Free',
        'pa': '🆓 ਮੁਫ਼ਤ',
        'ta': '🆓 இலவசம்',
        'te': '🆓 ఉచితం',
        'bn': '🆓 বিনামূল্যে',
      },
      'start_diagnosis': {
        'en': 'Start Diagnosis',
        'hi': 'Diagnosis Shuru Karo',
        'pa': 'ਜਾਂਚ ਸ਼ੁਰੂ ਕਰੋ',
        'ta': 'கண்டறிதல் தொடங்கு',
        'te': 'నిర్ధారణ ప్రారంభించండి',
        'bn': 'ডায়াগনসিস শুরু করুন',
      },
      'describe_hint': {
        'en': 'Describe in Hindi, English, or any language',
        'hi': 'Hindi, English ya kisi bhi bhasha mein batao',
        'pa': 'ਕਿਸੇ ਵੀ ਭਾਸ਼ਾ ਵਿੱਚ ਦੱਸੋ',
        'ta': 'எந்த மொழியிலும் விவரிக்கவும்',
        'te': 'ఏ భాషలోనైనా వివరించండి',
        'bn': 'যেকোনো ভাষায় বর্ণনা করুন',
      },

      // ── Quick Grid ────────────────────────────────────────
      'quick_actions': {
        'en': 'QUICK ACTIONS',
        'hi': 'QUICK ACTIONS',
        'pa': 'ਤੁਰੰਤ ਕਾਰਵਾਈਆਂ',
        'ta': 'விரைவு செயல்கள்',
        'te': 'శ్రీఘ్ర చర్యలు',
        'bn': 'দ্রুত অ্যাকশন',
      },
      'roadside_help': {
        'en': 'Roadside Help',
        'hi': 'Roadside Madad',
        'pa': 'ਸੜਕ ਕਿਨਾਰੇ ਮਦਦ',
        'ta': 'சாலை உதவி',
        'te': 'రోడ్‌సైడ్ సహాయం',
        'bn': 'রাস্তার পাশের সাহায্য',
      },
      'get_help_fast': {
        'en': 'Get help fast',
        'hi': 'Jaldi madad pao',
        'pa': 'ਜਲਦੀ ਮਦਦ ਲਓ',
        'ta': 'விரைந்து உதவி பெறுங்கள்',
        'te': 'త్వరగా సహాయం పొందండి',
        'bn': 'দ্রুত সাহায্য পান',
      },
      'find_workshops': {
        'en': 'Find workshops',
        'hi': 'Workshop dhundo',
        'pa': 'ਵਰਕਸ਼ਾਪ ਲੱਭੋ',
        'ta': 'பட்டறை தேடுங்கள்',
        'te': 'వర్క్‌షాప్ వెతకండి',
        'bn': 'ওয়ার্কশপ খুঁজুন',
      },
      'maintenance_tips': {
        'en': 'Maintenance Tips',
        'hi': 'Maintenance Tips',
        'pa': 'ਰੱਖ-ਰਖਾਅ ਸੁਝਾਅ',
        'ta': 'பராமரிப்பு குறிப்புகள்',
        'te': 'నిర్వహణ చిట్కాలు',
        'bn': 'রক্ষণাবেক্ষণ টিপস',
      },
      'keep_car_healthy': {
        'en': 'Keep car healthy',
        'hi': 'Gaadi theek rakho',
        'pa': 'ਕਾਰ ਨੂੰ ਤੰਦਰੁਸਤ ਰੱਖੋ',
        'ta': 'காரை ஆரோக்கியமாக வைக்கவும்',
        'te': 'కారును ఆరోగ్యంగా ఉంచండి',
        'bn': 'গাড়ি সুস্থ রাখুন',
      },
      'car_health': {
        'en': 'Car Health',
        'hi': 'Car Health',
        'pa': 'ਕਾਰ ਸਿਹਤ',
        'ta': 'கார் ஆரோக்கியம்',
        'te': 'కారు ఆరోగ్యం',
        'bn': 'গাড়ির স্বাস্থ্য',
      },
      'view_diagnostics': {
        'en': 'View diagnostics',
        'hi': 'Diagnostics dekho',
        'pa': 'ਡਾਇਗਨੋਸਟਿਕਸ ਵੇਖੋ',
        'ta': 'நோயறிதல்களை காண்க',
        'te': 'డయాగ్నొస్టిక్స్ చూడండి',
        'bn': 'ডায়াগনস্টিক্স দেখুন',
      },

      // ── Helper Toggle ─────────────────────────────────────
      'helper_on': {
        'en': 'Helper Mode — Active',
        'hi': 'Helper Mode — Active',
        'pa': 'ਮਦਦਗਾਰ ਮੋਡ — ਕਿਰਿਆਸ਼ੀਲ',
        'ta': 'உதவியாளர் முறை — செயலில்',
        'te': 'హెల్పర్ మోడ్ — యాక్టివ్',
        'bn': 'হেল্পার মোড — সক্রিয়',
      },
      'helper_off': {
        'en': 'Helper Mode — Off',
        'hi': 'Helper Mode — Off',
        'pa': 'ਮਦਦਗਾਰ ਮੋਡ — ਬੰਦ',
        'ta': 'உதவியாளர் முறை — அணைக்கப்பட்டது',
        'te': 'హెల్పర్ మోడ్ — ఆఫ్',
        'bn': 'হেল্পার মোড — বন্ধ',
      },
      'helper_on_sub': {
        'en': 'Receiving nearby help requests',
        'hi': 'Aas-paas ki help requests aa rahi hain',
        'pa': 'ਨੇੜੇ ਦੀਆਂ ਮਦਦ ਬੇਨਤੀਆਂ ਪ੍ਰਾਪਤ ਹੋ ਰਹੀਆਂ ਹਨ',
        'ta': 'அருகிலுள்ள உதவி கோரிக்கைகளை பெறுகிறோம்',
        'te': 'దగ్గరలో సహాయ అభ్యర్థనలు స్వీకరిస్తున్నాయి',
        'bn': 'কাছাকাছি সাহায্যের অনুরোধ পাচ্ছেন',
      },
      'helper_off_sub': {
        'en': 'Enable to earn by helping others',
        'hi': 'Enable karo aur doosron ki madad karke kamao',
        'pa': 'ਦੂਜਿਆਂ ਦੀ ਮਦਦ ਕਰਕੇ ਕਮਾਉਣ ਲਈ ਚਾਲੂ ਕਰੋ',
        'ta': 'மற்றவர்களுக்கு உதவி சம்பாதிக்க இயக்கவும்',
        'te': 'ఇతరులకు సహాయం చేసి సంపాదించడానికి ఎనేబుల్ చేయండి',
        'bn': 'অন্যদের সাহায্য করে উপার্জন করতে সক্রিয় করুন',
      },

      // ── Daily Section ─────────────────────────────────────
      'today': {
        'en': 'TODAY',
        'hi': 'AAJ',
        'pa': 'ਅੱਜ',
        'ta': 'இன்று',
        'te': 'ఈ రోజు',
        'bn': 'আজ',
      },
      'fuel_rates': {
        'en': 'Fuel Rates',
        'hi': 'Petrol/Diesel Rate',
        'pa': 'ਬਾਲਣ ਦਰਾਂ',
        'ta': 'எரிபொருள் விகிதங்கள்',
        'te': 'ఇంధన రేట్లు',
        'bn': 'জ্বালানি মূল্য',
      },
      'fuel_sub': {
        'en': 'Petrol/Diesel daily update',
        'hi': 'Roz ka rate dekhein',
        'pa': 'ਰੋਜ਼ਾਨਾ ਬਾਲਣ ਅੱਪਡੇਟ',
        'ta': 'தினசரி புதுப்பிப்பு',
        'te': 'రోజువారీ అప్‌డేట్',
        'bn': 'দৈনিক আপডেট',
      },
      'fuel_tag': {
        'en': 'Daily',
        'hi': 'Daily',
        'pa': 'ਰੋਜ਼ਾਨਾ',
        'ta': 'தினசரி',
        'te': 'రోజువారీ',
        'bn': 'প্রতিদিন',
      },
      'highway_alerts': {
        'en': 'Highway Alerts',
        'hi': 'Highway Alerts',
        'pa': 'ਹਾਈਵੇ ਅਲਰਟ',
        'ta': 'நெடுஞ்சாலை எச்சரிக்கைகள்',
        'te': 'హైవే అలర్ట్‌లు',
        'bn': 'হাইওয়ে সতর্কতা',
      },
      'highway_sub': {
        'en': 'Jam • Weather • Police',
        'hi': 'Jam • Mausam • Police',
        'pa': 'ਜਾਮ • ਮੌਸਮ • ਪੁਲਿਸ',
        'ta': 'நெரிசல் • வானிலை • போலீஸ்',
        'te': 'జామ్ • వాతావరణం • పోలీసు',
        'bn': 'জ্যাম • আবহাওয়া • পুলিশ',
      },
      'highway_tag': {
        'en': 'Live',
        'hi': 'Live',
        'pa': 'ਲਾਈਵ',
        'ta': 'நேரடி',
        'te': 'లైవ్',
        'bn': 'লাইভ',
      },
      'daily_tip': {
        'en': "Today's Tip",
        'hi': 'Aaj Ka Tip',
        'pa': 'ਅੱਜ ਦੀ ਸਲਾਹ',
        'ta': 'இன்றைய குறிப்பு',
        'te': 'నేటి చిట్కా',
        'bn': 'আজকের টিপস',
      },
      'daily_tip_sub': {
        'en': 'Raahi daily car tip',
        'hi': 'Raahi Bhaiya ka daily tip',
        'pa': 'ਰਾਹੀ ਦੀ ਰੋਜ਼ਾਨਾ ਸਲਾਹ',
        'ta': 'ராஹியின் தினசரி குறிப்பு',
        'te': 'రాహి రోజువారీ చిట్కా',
        'bn': 'রাহির দৈনিক টিপস',
      },
      'daily_tip_tag': {
        'en': 'New',
        'hi': 'New',
        'pa': 'ਨਵਾਂ',
        'ta': 'புதியது',
        'te': 'కొత్తది',
        'bn': 'নতুন',
      },
      'nearby_places': {
        'en': 'Nearby Places',
        'hi': 'Aas-paas ki jagahen',
        'pa': 'ਨੇੜੇ ਦੀਆਂ ਥਾਵਾਂ',
        'ta': 'அருகிலுள்ள இடங்கள்',
        'te': 'దగ్గరలోని స్థలాలు',
        'bn': 'কাছের স্থান',
      },
      'nearby_sub': {
        'en': 'Dhaba • Parking • ATM',
        'hi': 'Dhaba • Parking • ATM',
        'pa': 'ਢਾਬਾ • ਪਾਰਕਿੰਗ • ATM',
        'ta': 'தாபா • பார்க்கிங் • ATM',
        'te': 'ఢాభా • పార్కింగ్ • ATM',
        'bn': 'ঢাবা • পার্কিং • ATM',
      },
      'nearby_tag': {
        'en': 'GPS',
        'hi': 'GPS',
        'pa': 'GPS',
        'ta': 'GPS',
        'te': 'GPS',
        'bn': 'GPS',
      },

      // ── Streak Card ───────────────────────────────────────
      'daily_streak': {
        'en': 'Daily Streak',
        'hi': 'Daily Streak',
        'pa': 'ਰੋਜ਼ਾਨਾ ਸਟ੍ਰੀਕ',
        'ta': 'தினசரி தொடர்',
        'te': 'డైలీ స్ట్రీక్',
        'bn': 'ডেইলি স্ট্রিক',
      },
      'streak_sub': {
        'en': 'Come daily, earn rewards',
        'hi': 'Roz aao, rewards kamao',
        'pa': 'ਰੋਜ਼ ਆਓ, ਇਨਾਮ ਕਮਾਓ',
        'ta': 'தினமும் வாருங்கள், வெகுமதிகள் பெறுங்கள்',
        'te': 'రోజూ రండి, రివార్డ్స్ సంపాదించండి',
        'bn': 'প্রতিদিন আসুন, পুরস্কার পান',
      },
      'check_in': {
        'en': 'Check-in',
        'hi': 'Check-in Karo',
        'pa': 'ਚੈੱਕ-ਇਨ',
        'ta': 'செக்-இன்',
        'te': 'చెక్-ఇన్',
        'bn': 'চেক-ইন',
      },

      // ── Car Status Labels ─────────────────────────────────
      'odometer': {
        'en': 'Odometer',
        'hi': 'Odometer',
        'pa': 'ਓਡੋਮੀਟਰ',
        'ta': 'ஓடோமீட்டர்',
        'te': 'ఓడోమీటర్',
        'bn': 'ওডোমিটার',
      },
      'last_service': {
        'en': 'Last Service',
        'hi': 'Last Service',
        'pa': 'ਆਖਰੀ ਸੇਵਾ',
        'ta': 'கடைசி சேவை',
        'te': 'చివరి సర్వీస్',
        'bn': 'শেষ সার্ভিস',
      },
      'fuel_type': {
        'en': 'Fuel Type',
        'hi': 'Fuel Type',
        'pa': 'ਬਾਲਣ ਕਿਸਮ',
        'ta': 'எரிபொருள் வகை',
        'te': 'ఇంధన రకం',
        'bn': 'জ্বালানির ধরন',
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
