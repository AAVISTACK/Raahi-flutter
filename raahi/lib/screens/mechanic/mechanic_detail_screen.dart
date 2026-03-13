// =====================================================
// mechanic_detail_screen.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class MechanicDetailScreen extends StatefulWidget {
  final String mechanicId;
  const MechanicDetailScreen({super.key, required this.mechanicId});

  @override
  State<MechanicDetailScreen> createState() => _MechanicDetailScreenState();
}

class _MechanicDetailScreenState extends State<MechanicDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Mechanic Detail'), backgroundColor: AppTheme.navyLight),
      body: const Center(
        child: Text('Mechanic detail yahan aayegi', style: TextStyle(color: AppTheme.textSecondary)),
      ),
    );
  }
}
