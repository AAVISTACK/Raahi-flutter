// ============================================================
// lib/screens/admin/selfie_review_screen.dart
// Admin ka screen — pending selfies approve/reject karo
// Simple web browser mein bhi kaam karega
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SelfieReviewScreen extends StatefulWidget {
  const SelfieReviewScreen({super.key});
  @override
  State<SelfieReviewScreen> createState() => _SelfieReviewScreenState();
}

class _SelfieReviewScreenState extends State<SelfieReviewScreen> {
  final _api         = ApiService();
  final _secretCtrl  = TextEditingController();
  final _noteCtrl    = TextEditingController();

  List<dynamic> _pending = [];
  bool   _loading        = false;
  bool   _loggedIn       = false;
  String _error          = '';

  Future<void> _login() async {
    if (_secretCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await _api.getWithAdminSecret(
          '/selfie/pending', _secretCtrl.text);
      setState(() {
        _pending  = res['pending'] ?? [];
        _loggedIn = true;
        _loading  = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Wrong secret ya network error'; });
    }
  }

  Future<void> _review(String id, String action, {String? note}) async {
    setState(() => _loading = true);
    try {
      await _api.putWithAdminSecret(
        '/selfie/$id/review',
        _secretCtrl.text,
        {'action': action, 'note': note ?? _noteCtrl.text},
      );
      _noteCtrl.clear();
      // List refresh
      setState(() => _pending.removeWhere((p) => p['id'] == id));
      setState(() => _loading = false);
      _snack(action == 'approve' ? '✅ Approved!' : '❌ Rejected', action == 'approve');
    } catch (e) {
      setState(() => _loading = false);
      _snack('Error: $e', false);
    }
  }

  void _snack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.green : AppTheme.red,
    ));
  }

  @override
  void dispose() {
    _secretCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: Text(
          _loggedIn ? 'Selfie Review (${_pending.length} pending)' : 'Admin Login',
          style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700),
        ),
        actions: _loggedIn ? [
          IconButton(
            onPressed: _login,
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
          )
        ] : null,
      ),
      body: _loggedIn ? _buildReviewList() : _buildLogin(),
    );
  }

  // ── Login ─────────────────────────────────────────────────
  Widget _buildLogin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.admin_panel_settings, color: AppTheme.primary, size: 48),
          const SizedBox(height: 16),
          const Text('Admin Panel', style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          TextField(
            controller: _secretCtrl,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Admin Secret daalo',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true, fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.cardBorder)),
              prefixIcon: const Icon(Icons.lock, color: AppTheme.textMuted),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error, style: const TextStyle(color: AppTheme.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Review List ───────────────────────────────────────────
  Widget _buildReviewList() {
    if (_pending.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🎉', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Sab review ho gaya!', style: TextStyle(
            color: AppTheme.green, fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Koi pending selfie nahi hai',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (_, i) => _buildSelfieCard(_pending[i]),
    );
  }

  Widget _buildSelfieCard(Map selfie) {
    final user = selfie['user'] as Map? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // User info
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['name'] ?? 'Unknown',
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text(user['phone'] ?? '',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ])),
            Text(_timeAgo(selfie['createdAt']),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ]),
        ),

        // Selfie image
        if (selfie['selfieUrl'] != null)
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: selfie['selfieUrl'].toString().startsWith('data:')
                ? Image.memory(
                    Uri.parse(selfie['selfieUrl']).data!.contentAsBytes(),
                    width: double.infinity, height: 240,
                    fit: BoxFit.cover,
                  )
                : Container(height: 240, color: AppTheme.navyLight,
                    child: const Center(child: Icon(Icons.image, color: AppTheme.textMuted, size: 40))),
          ),

        // Note field + buttons
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reject reason (optional)',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                filled: true, fillColor: AppTheme.navyLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.cardBorder)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              // Reject
              Expanded(child: OutlinedButton.icon(
                onPressed: _loading ? null : () => _showRejectDialog(selfie['id']),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: BorderSide(color: AppTheme.red.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 10),
              // Approve
              Expanded(child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _review(selfie['id'], 'approve'),
                icon: const Icon(Icons.check, size: 18, color: Colors.black),
                label: const Text('Approve ✓',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _showRejectDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Reject Reason', style: TextStyle(color: AppTheme.textPrimary,
            fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ...[
            'Chehra clear nahi hai',
            'Sunglasses laga rakhi hai',
            'Andhera zyada hai',
            'Poora chehra nahi dikh raha',
            'Fake/duplicate photo',
          ].map((reason) => ListTile(
            title: Text(reason, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            onTap: () {
              Navigator.pop(context);
              _review(id, 'reject', note: reason);
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
