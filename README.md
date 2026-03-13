# 🚗 Raahi — Flutter App

**Highway par hamesha saath** — AI-powered roadside assistance for Indian highway drivers.

---

## 📱 Screens Included

| Screen | File | Description |
|--------|------|-------------|
| Splash | `splash_screen.dart` | Animated logo + auto-navigate |
| Onboarding | `onboarding_screen.dart` | 3-slide intro |
| Phone Login | `auth/phone_login_screen.dart` | OTP login |
| OTP Verify | `auth/otp_screen.dart` | 6-digit OTP boxes |
| Profile Setup | `auth/profile_setup_screen.dart` | Name + vehicle type |
| Home | `home/home_screen.dart` | Dashboard with SOS + 4 actions |
| Request Help | `p2p/request_help_screen.dart` | Create P2P help job |
| Active Job | `p2p/active_job_screen.dart` | Track live job + OTP |
| Job Offers | `p2p/job_offers_screen.dart` | Accept/decline as helper |
| AI Mechanic | `ai/ai_mechanic_screen.dart` | Chat + Voice with AI |
| Mechanics Map | `mechanic/mechanics_map_screen.dart` | Nearby workshops list |
| SOS | `sos/sos_screen.dart` | Emergency button + countdown |
| Profile | `profile/profile_screen.dart` | User profile + settings |
| Subscription | `subscription/subscription_screen.dart` | Mechanic plans |
| Mechanic Register | (in subscription file) | Workshop registration |

---

## ⚙️ Setup Instructions

### 1. Prerequisites
```bash
flutter --version   # Needs Flutter 3.0+
dart --version      # Needs Dart 3.0+
```

### 2. Install Dependencies
```bash
cd raahi
flutter pub get
```

### 3. Configure API Keys

Open `lib/utils/constants.dart` and replace:
```dart
static const String googleMapsKey = 'YOUR_GOOGLE_MAPS_API_KEY';
static const String razorpayKey = 'YOUR_RAZORPAY_KEY_ID';
static const String openAiKey = 'YOUR_OPENAI_API_KEY';
```

Also update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

### 4. Firebase Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase project
flutterfire configure
```

### 5. Backend URL
Update `lib/utils/constants.dart`:
```dart
static const String baseUrl = 'https://your-api.com/api/v1';
static const String wsUrl = 'wss://your-ws.com';
```

### 6. Run the App
```bash
flutter run                    # Debug mode
flutter run --release          # Release mode
flutter build apk --release    # Build APK
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                  # Entry point + router
├── theme/
│   └── app_theme.dart         # Colors, fonts, theme
├── models/
│   └── models.dart            # UserModel, HelpJob, MechanicModel, etc.
├── services/
│   ├── api_service.dart       # All REST API calls
│   ├── socket_service.dart    # WebSocket real-time
│   └── location_service.dart  # GPS tracking
├── utils/
│   └── constants.dart         # API keys, URLs, config
└── screens/
    ├── splash_screen.dart
    ├── onboarding_screen.dart
    ├── auth/
    ├── home/
    ├── p2p/
    ├── ai/
    ├── mechanic/
    ├── sos/
    ├── profile/
    └── subscription/
```

---

## 🔧 Third-party Integrations

| Service | Purpose | Package |
|---------|---------|---------|
| Google Maps | Maps + Location | `google_maps_flutter` |
| Firebase Auth | Phone OTP | `firebase_auth` |
| Firebase FCM | Push Notifications | `firebase_messaging` |
| Razorpay | Payments | `razorpay_flutter` |
| OpenAI/Claude | AI Mechanic backend | REST API |
| Socket.io | Real-time P2P | `socket_io_client` |
| Google STT | Voice input | `speech_to_text` |
| Google TTS | Voice output | `flutter_tts` |

---

## 💰 Revenue Streams Implemented

1. **Mechanic Subscriptions** — Basic ₹999/mo, Pro ₹2499/mo
2. **P2P Commission** — 15% on every help transaction
3. **Future:** Insurance affiliate, fleet B2B

---

## 📞 Support
- App: raahi
- Contact: support@raahi.in
- Highway helpline: 18001234567
