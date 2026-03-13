// ============================================================
// lib/services/notification_service.dart
// Daily push notifications — fuel rates, alerts, tips, streak
// Firebase Cloud Messaging (FCM)
// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _api       = ApiService();

  // ── Initialize ───────────────────────────────────────────
  Future<void> init() async {
    // Permission maango
    final settings = await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _registerToken();
      _setupHandlers();
    }
  }

  // FCM token backend pe register karo
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final prefs       = await SharedPreferences.getInstance();
      final savedToken  = prefs.getString('fcm_token');

      if (savedToken != token) {
        await _api.put('/auth/fcm-token', {'fcmToken': token});
        await prefs.setString('fcm_token', token);
      }

      // Token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _api.put('/auth/fcm-token', {'fcmToken': newToken});
        await prefs.setString('fcm_token', newToken);
      });
    } catch (e) {
      debugPrint('FCM token register error: $e');
    }
  }

  // ── Message Handlers ─────────────────────────────────────
  void _setupHandlers() {
    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      // In-app notification show karo (snackbar ya overlay)
      _handleMessage(message);
    });

    // Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message);
    });

    // App closed pe aaya tha
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _navigateFromMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    // Notification type ke hisaab se handle karo
    switch (data['type']) {
      case 'fuel_update':
        // Fuel rates screen pe refresh
        break;
      case 'new_alert':
        // Alerts feed mein show karo
        break;
      case 'streak_reminder':
        // Streak screen pe jayein
        break;
      case 'new_job':
        // Job offers screen
        break;
    }
  }

  void _navigateFromMessage(RemoteMessage message) {
    final type = message.data['type'];
    // GoRouter se navigate karo — router reference chahiye hogi
    // Abhi ke liye sirf log karo
    debugPrint('Navigate from notification: $type');
  }

  // ── Subscribe to Topics ──────────────────────────────────

  // City-specific alerts ke liye subscribe karo
  Future<void> subscribeToCityAlerts(String city) async {
    final topic = 'alerts_${city.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to: $topic');
  }

  // Daily tips notification ke liye
  Future<void> subscribeToTips() async {
    await _messaging.subscribeToTopic('daily_tips');
  }

  // Fuel update notification
  Future<void> subscribeToFuelUpdates(String city) async {
    final topic = 'fuel_${city.toLowerCase().replaceAll(' ', '_')}';
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe
  Future<void> unsubscribe(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

// ── Background Message Handler (top-level) ───────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}
