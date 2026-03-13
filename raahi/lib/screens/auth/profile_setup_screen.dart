import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  String _selectedVehicle = 'car';
  bool _loading = false;

  final _vehicles = [
    {'id': 'car', 'label': 'Car', 'emoji': '🚗'},
    {'id': 'truck', 'label': 'Truck', 'emoji': '🚛'},
    {'id': 'bike', 'label': 'Bike', 'emoji': '🏍️'},
    {'id': 'bus', 'label': 'Bus', 'emoji': '🚌'},
    {'id': 'auto', 'label': 'Auto', 'emoji': '🛺'},
  ];

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naam toh daalo bhai!')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().updateProfile({
        'name': _nameCtrl.text.trim(),
        'vehicle_type': _selectedVehicle,
        'vehicle_reg': _regCtrl.text.trim().toUpperCase(),
      });
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error aaya. Dobara try karo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Profile Banao 📝',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('Ek baar setup karo, phir sab easy ho jaayega',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),

              // Name
              _label('Aapka Naam *'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ramesh Kumar',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 24),

              // Vehicle Type
              _label('Gaadi Kaisi Hai?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _vehicles.map((v) {
                  final selected = _selectedVehicle == v['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedVehicle = v['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.saffron.withOpacity(0.15) : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.saffron : AppTheme.cardBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(v['emoji']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(v['label']!, style: TextStyle(
                            color: selected ? AppTheme.saffron : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Vehicle Reg
              _label('Gaadi Number (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _regCtrl,
                style: const TextStyle(color: AppTheme.textPrimary, letterSpacing: 2),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'MH 12 AB 1234',
                  prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppTheme.textMuted),
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Chalo Shuru Karte Hain! 🚀',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
}
