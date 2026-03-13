# 🔑 Raahi — Setup Guide
## Exact File Paths + Line Numbers

---

## ✅ STEP 1 — Google Maps API Key

### Android  →  `android/app/src/main/AndroidManifest.xml`
```
Line 43:  android:value="YOUR_GOOGLE_MAPS_API_KEY"
                          ↑ YAHAN APNI KEY PASTE KARO
```

### iOS  →  `ios/Runner/AppDelegate.swift`
```
Line 10:  GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
                                     ↑ YAHAN APNI KEY PASTE KARO
```

### constants.dart  →  `lib/utils/constants.dart`
```
Line 17:  static const String googleMapsKey = 'YOUR_GOOGLE_MAPS_API_KEY';
                                               ↑ YAHAN BHI SAME KEY
```

**Key kaise milegi:**
```
1. https://console.cloud.google.com jaao
2. Project select karo ya banao
3. APIs & Services → Library
4. "Maps SDK for Android" → Enable
5. "Maps SDK for iOS" → Enable
6. APIs & Services → Credentials → + Create Credentials → API Key
7. Copy karo
```

---

## ✅ STEP 2 — Razorpay Key

### `lib/utils/constants.dart`
```
Line 24:  static const String razorpayKey = 'rzp_test_YOUR_KEY_HERE';
                                             ↑ YAHAN PASTE KARO
```

**Key kaise milegi:**
```
1. https://dashboard.razorpay.com → Login/Signup
2. Settings (gear icon) → API Keys
3. "Generate Test Key" click karo
4. Key ID copy karo (rzp_test_XXXXXXXXXX)
```

---

## ✅ STEP 3 — OpenAI / Gemini Key

### `lib/utils/constants.dart`
```
Line 33:  static const String openAiKey = 'YOUR_OPENAI_OR_GEMINI_KEY';
                                           ↑ YAHAN PASTE KARO
```

**OpenAI key kaise milegi:**
```
1. https://platform.openai.com/api-keys
2. "+ Create new secret key"
3. Copy karo (sk-proj-XXXXXXXXXXXXXXX)
```

**Gemini key kaise milegi:**
```
1. https://aistudio.google.com/app/apikey
2. "Create API key"
3. Copy karo (AIzaSy-XXXXXXXXXXXXXXXXXX)
```

**⚠️ PRODUCTION WARNING:**
Dev mein constants.dart mein rakho, but production mein
apne backend Node.js server ki `.env` file mein rakho:
```
# .env file (backend mein)
OPENAI_API_KEY=sk-proj-XXXXXXXX
```

---

## ✅ STEP 4 — Firebase Setup

### Android  →  `android/app/google-services.json`
```
Currently placeholder file hai — real file se replace karo
```

### iOS  →  `ios/Runner/GoogleService-Info.plist`
```
Currently placeholder file hai — real file se replace karo
```

**Firebase files kaise milegi:**
```
1. https://console.firebase.google.com
2. "Add project" → Name: Raahi → Create
3. Project dashboard mein Android icon click karo:
   - Package name: com.raahi.app
   - App nickname: Raahi
   - "Register app" → Download google-services.json
   - Paste karo: android/app/google-services.json

4. iOS icon click karo:
   - Bundle ID: com.raahi.app
   - "Register app" → Download GoogleService-Info.plist
   - Paste karo: ios/Runner/GoogleService-Info.plist

5. Firebase Console → Authentication → Sign-in methods
   → Phone → Enable karo
```

---

## ✅ STEP 5 — Backend URL

### `lib/utils/constants.dart`
```
Line 9:   static const String baseUrl = '...';
Line 10:  static const String wsUrl   = '...';
```

**Different environments ke liye:**
```dart
// Android Emulator (localhost):
baseUrl = 'http://10.0.2.2:3000/api/v1'
wsUrl   = 'ws://10.0.2.2:3001'

// Real Device (same WiFi):
baseUrl = 'http://192.168.1.5:3000/api/v1'   // apna IP check: ipconfig/ifconfig
wsUrl   = 'ws://192.168.1.5:3001'

// Production:
baseUrl = 'https://api.raahi.in/api/v1'
wsUrl   = 'wss://ws.raahi.in'
```

---

## ✅ STEP 6 — Fonts (Optional but Recommended)

### Option A — Google Fonts Package (Already Added, Zero Setup)
```
google_fonts package already pubspec.yaml mein hai.
app_theme.dart mein Rajdhani automatically load hoga.
Kuch karne ki zaroorat nahi! ✓
```

### Option B — Local Fonts (Better Performance)
```
1. https://fonts.google.com/specimen/Rajdhani → Download family
2. TTF files rakho: assets/fonts/
   - assets/fonts/Rajdhani-Regular.ttf
   - assets/fonts/Rajdhani-SemiBold.ttf
   - assets/fonts/Rajdhani-Bold.ttf
3. pubspec.yaml mein fonts: section uncomment karo (bottom mein)
```

---

## ✅ STEP 7 — Lottie Animations (Optional)

**`assets/lottie/` mein yeh files rakho:**
```
loading.json     → https://lottiefiles.com → search "loading orange"
sos_pulse.json   → https://lottiefiles.com → search "pulse red"
success.json     → https://lottiefiles.com → search "success check"
```

---

## 🚀 Final Run Commands

```bash
# Step 1: Folder mein jaao
cd raahi

# Step 2: Dependencies install karo
flutter pub get

# Step 3: Firebase configure karo (ek baar)
dart pub global activate flutterfire_cli
flutterfire configure --project=driver-sahayak

# Step 4: Run karo
flutter run                     # Debug
flutter run --release           # Release
flutter build apk --release     # APK banao
```

---

## 📁 Complete File Structure (All Files)

```
raahi/
│
├── 🔑 android/app/google-services.json          ← Firebase Android
├── 🔑 android/app/src/main/AndroidManifest.xml  ← Maps Key (Line 43)
├── 📄 android/app/build.gradle                  ← Firebase plugin
├── 📄 android/build.gradle                      ← Google services classpath
├── 📄 android/gradle.properties
├── 📄 android/settings.gradle
├── 📄 android/app/src/main/kotlin/.../MainActivity.kt
│
├── 🔑 ios/Runner/GoogleService-Info.plist        ← Firebase iOS
├── 🔑 ios/Runner/AppDelegate.swift               ← Maps Key (Line 10)
├── 📄 ios/Runner/Info.plist                      ← Permissions
│
├── assets/
│   ├── images/     ← App images yahan
│   ├── lottie/     ← Lottie JSON files yahan
│   └── fonts/      ← TTF font files yahan (optional)
│
├── lib/
│   ├── 🔑 utils/constants.dart    ← URLs + Keys (Lines 9,17,24,33)
│   ├── main.dart
│   ├── theme/app_theme.dart
│   ├── models/models.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── socket_service.dart
│   │   └── location_service.dart
│   └── screens/ (14 screens)
│
└── pubspec.yaml
```

---

**🔑 = File jahan key/config dalni hai**
**📄 = Auto-configured, touch karne ki zaroorat nahi**
