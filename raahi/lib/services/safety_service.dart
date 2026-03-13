// ============================================================
// lib/services/safety_service.dart
// Emergency contact, live location share, unsafe report
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class EmergencyContact {
  final String name;
  final String phone;
  const EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory EmergencyContact.fromJson(Map<String, dynamic> j) =>
      EmergencyContact(name: j['name'], phone: j['phone']);
}

class SafetyService {
  static final SafetyService _i = SafetyService._();
  factory SafetyService() => _i;
  SafetyService._();

  static const _keyContacts    = 'emergency_contacts';
  static const _keyAadhaarDone = 'aadhaar_verified';

  // ── Emergency Contacts ────────────────────────────────────
  Future<List<EmergencyContact>> getContacts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyContacts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EmergencyContact.fromJson(e)).toList();
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyContacts, jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }

  Future<void> addContact(EmergencyContact c) async {
    final list = await getContacts();
    if (list.length >= 3) list.removeAt(0); // max 3
    list.add(c);
    await saveContacts(list);
  }

  Future<void> removeContact(int index) async {
    final list = await getContacts();
    list.removeAt(index);
    await saveContacts(list);
  }

  // ── Live Location Share via SMS ───────────────────────────
  // Helper accept karne ke baad trusted contacts ko SMS
  Future<void> shareLiveLocationWithContacts({
    required double lat,
    required double lng,
    required String helperName,
    required String helperPhone,
    String? jobId,
  }) async {
    final contacts = await getContacts();
    if (contacts.isEmpty) return;

    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';
    final msg = Uri.encodeComponent(
      '🚨 Raahi Safety Alert\n\n'
      'Main highway pe hoon aur mujhe help mil rahi hai.\n\n'
      '📍 Meri location: $mapsLink\n'
      '👤 Helper: $helperName ($helperPhone)\n\n'
      'Yeh message Raahi app ne automatically bheja hai.'
    );

    // SMS to first contact (primary)
    final primary = contacts.first;
    final smsUrl = 'sms:${primary.phone}?body=$msg';
    final uri = Uri.parse(smsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ── "I Feel Unsafe" Alert ─────────────────────────────────
  Future<void> sendUnsafeAlert({
    required double lat,
    required double lng,
    String? helperName,
    String? helperPhone,
  }) async {
    final contacts = await getContacts();
    final mapsLink = 'https://maps.google.com/?q=$lat,$lng';

    final msg = Uri.encodeComponent(
      '🆘 EMERGENCY — Raahi App\n\n'
      'MUJHE MADAD CHAHIYE!\n\n'
      '📍 Meri location: $mapsLink\n'
      '${helperName != null ? "⚠️ Helper: $helperName ($helperPhone)\n" : ""}'
      '\nAbhi mujhe call karo ya police ko inform karo.\n'
      'Police: 112'
    );

    // SMS + call to all contacts
    for (final c in contacts) {
      final uri = Uri.parse('sms:${c.phone}?body=$msg');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        break; // pehle wale ko bhejo, baaki background mein
      }
    }

    // Police call option
    await Future.delayed(const Duration(seconds: 1));
    final policeUri = Uri.parse('tel:112');
    if (await canLaunchUrl(policeUri)) {
      await launchUrl(policeUri);
    }
  }

  // ── Aadhaar Verification Status ──────────────────────────
  Future<bool> isAadhaarVerified() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyAadhaarDone) ?? false;
  }

  Future<void> setAadhaarVerified(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyAadhaarDone, val);
  }

  // ── Report Helper ─────────────────────────────────────────
  // ApiService ko call karna hoga — yahan sirf data prepare karta hoon
  Map<String, dynamic> buildReport({
    required String helperId,
    required String jobId,
    required String reason,
    String? details,
  }) {
    return {
      'helper_id': helperId,
      'job_id': jobId,
      'reason': reason,
      'details': details ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
