// ============================================================
// lib/screens/safety/emergency_contacts_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/safety_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final bool isOnboarding;
  const EmergencyContactsScreen({super.key, this.isOnboarding = false});
  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final c = await SafetyService().getContacts();
    if (mounted) setState(() { _contacts = c; _loading = false; });
  }

  void _addContact() {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Emergency Contact Add Karo',
              style: TextStyle(color: AppTheme.textPrimary,
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _buildField(nameCtrl, 'Naam', 'Jaise: Mummy, Papa, Bhai'),
          const SizedBox(height: 12),
          _buildField(phoneCtrl, 'Phone', '+91 98765 43210',
              type: TextInputType.phone),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                await SafetyService().addContact(EmergencyContact(
                    name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim()));
                if (mounted) Navigator.pop(context);
                _load();
              },
              child: const Text('Save Karo', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint,
      {TextInputType type = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, keyboardType: type,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(hintText: hint)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Emergency Contacts'),
          backgroundColor: AppTheme.navyLight),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
          : ListView(padding: const EdgeInsets.all(20), children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.red.withOpacity(0.2)),
                ),
                child: const Row(children: [
                  Text('🛡️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tumhari Safety, Humari Zimmedari',
                          style: TextStyle(color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 3),
                      Text('Helper accept karte hi yeh contacts ko tumhari location SMS ho jaayegi.',
                          style: TextStyle(color: AppTheme.textMuted,
                              fontSize: 12, height: 1.4)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('Trusted Contacts (Max 3)',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Contacts
              ..._contacts.asMap().entries.map((e) {
                final i = e.key; final c = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder)),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: AppTheme.saffron.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Center(child: Text(
                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.saffron,
                              fontWeight: FontWeight.w700, fontSize: 18))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(c.phone, style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    )),
                    if (i == 0) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppTheme.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Primary', style: TextStyle(
                          color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async { await SafetyService().removeContact(i); _load(); },
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                  ]),
                );
              }),

              if (_contacts.length < 3)
                GestureDetector(
                  onTap: _addContact,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.saffron.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_rounded, color: AppTheme.saffron),
                      SizedBox(width: 8),
                      Text('Contact Add Karo', style: TextStyle(
                          color: AppTheme.saffron, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              const SizedBox(height: 32),
              if (widget.isOnboarding) SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_contacts.isEmpty
                      ? 'Skip (Baad mein add karna)'
                      : 'Save aur Aage Badho ✓',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
    );
  }
}
