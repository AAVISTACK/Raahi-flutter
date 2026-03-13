// ============================================================
// lib/screens/safety/selfie_verify_screen.dart
// FREE selfie verification — Admin manually approve karta hai
// Flow: Selfie lo → Submit → Admin dekhta hai → Approve → BASIC tier
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SelfieVerifyScreen extends StatefulWidget {
  const SelfieVerifyScreen({super.key});
  @override
  State<SelfieVerifyScreen> createState() => _SelfieVerifyScreenState();
}

class _SelfieVerifyScreenState extends State<SelfieVerifyScreen> {
  final _api    = ApiService();
  final _picker = ImagePicker();

  File?   _selfieFile;
  String? _selfieBase64;
  bool    _loading       = false;
  bool    _submitted     = false;
  String  _currentStatus = 'NONE'; // NONE | PENDING | APPROVED | REJECTED
  String? _adminNote;
  String  _error         = '';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  // ── Check existing status ─────────────────────────────────
  Future<void> _checkStatus() async {
    try {
      final res = await _api.get('/selfie/status');
      final selfie = res['selfie'];
      if (selfie != null) {
        setState(() {
          _currentStatus = selfie['status'] ?? 'NONE';
          _adminNote     = selfie['adminNote'];
          _submitted     = _currentStatus == 'PENDING';
        });
      }
    } catch (_) {}
  }

  // ── Selfie lo ────────────────────────────────────────────
  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source:         ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Front camera
        imageQuality:   60,   // Compress — upload size kam
        maxWidth:       800,
        maxHeight:      800,
      );
      if (photo == null) return;

      final file  = File(photo.path);
      final bytes = await file.readAsBytes();

      // Size check
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        _setError('Image 2MB se zyada hai. Dobara lo.');
        return;
      }

      setState(() {
        _selfieFile   = file;
        _selfieBase64 = base64Encode(bytes);
        _error        = '';
      });
    } catch (e) {
      _setError('Camera open nahi hua. Permission check karo.');
    }
  }

  // ── Gallery se bhi le sako ───────────────────────────────
  Future<void> _fromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source:       ImageSource.gallery,
        imageQuality: 60,
        maxWidth:     800,
        maxHeight:    800,
      );
      if (photo == null) return;
      final file  = File(photo.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _selfieFile   = file;
        _selfieBase64 = base64Encode(bytes);
        _error        = '';
      });
    } catch (e) {
      _setError('Image select nahi hua.');
    }
  }

  String _loadingMsg = 'Submit ho raha hai...';

  // ── Submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selfieBase64 == null) { _setError('Pehle selfie lo'); return; }
    setState(() { _loading = true; _error = ''; _loadingMsg = '📤 Upload ho raha hai...'; });

    try {
      setState(() => _loadingMsg = '🤖 AI face check kar raha hai...');
      final res = await _api.post('/selfie/submit', {
        'selfieBase64': _selfieBase64,
        'mimeType':     'image/jpeg',
      });

      setState(() => _loading = false);

      // Auto approved!
      if (res['autoApproved'] == true) {
        setState(() => _currentStatus = 'APPROVED');
        return;
      }

      // Pending — manual review
      setState(() { _submitted = true; _currentStatus = 'PENDING'; });

    } catch (e) {
      setState(() => _loading = false);
      final errStr = e.toString();

      // Face check fail — parse reason from backend
      if (errStr.contains('reason') || errStr.contains('Selfie verify nahi')) {
        // Try to extract reason
        final reasonMatch = RegExp(r'reason.*?:.*?"([^"]+)"').firstMatch(errStr);
        final reason = reasonMatch?.group(1) ?? 'Photo quality theek nahi — dobara try karo';
        _setError(reason);
      } else {
        _setError(errStr.replaceAll('Exception: ', ''));
      }
    }
  }

  void _setError(String msg) => setState(() => _error = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Selfie Verification',
            style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Status ke hisaab se screen dikhao
    switch (_currentStatus) {
      case 'APPROVED':
        return _buildApproved();
      case 'PENDING':
        return _buildPending();
      case 'REJECTED':
        return _buildRejected();
      default:
        return _buildForm();
    }
  }

  // ── Success: Approved ─────────────────────────────────────
  Widget _buildApproved() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.green.withOpacity(0.12),
              border: Border.all(color: AppTheme.green.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.verified_user, color: AppTheme.green, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Verified! ✓', style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 28, fontWeight: FontWeight.w800,
              color: AppTheme.green)),
          const SizedBox(height: 8),
          const Text('Tumhari selfie verify ho gayi.\nAb P2P jobs apply kar sakte ho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 24),
          _tierBadge('BASIC', AppTheme.yellow),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Wapas Jao', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Pending: Under review ─────────────────────────────────
  Widget _buildPending() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.yellow.withOpacity(0.1),
              border: Border.all(color: AppTheme.yellow.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.hourglass_empty_rounded, color: AppTheme.yellow, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Review Mein Hai ⏳', style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 26, fontWeight: FontWeight.w800,
              color: AppTheme.yellow)),
          const SizedBox(height: 10),
          const Text('Tumhari selfie admin ke paas hai.\n24 ghante mein approve/reject hogi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Row(children: [
              Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Approve hone pe notification aayega',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Wapas Jao', style: TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Rejected: Try again ───────────────────────────────────
  Widget _buildRejected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.red.withOpacity(0.1),
              border: Border.all(color: AppTheme.red.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.cancel_outlined, color: AppTheme.red, size: 44),
          ),
          const SizedBox(height: 20),
          const Text('Verify Nahi Hui', style: TextStyle(
              fontFamily: 'Rajdhani', fontSize: 26, fontWeight: FontWeight.w800,
              color: AppTheme.red)),
          const SizedBox(height: 10),
          if (_adminNote != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.red.withOpacity(0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, color: AppTheme.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Reason: $_adminNote',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Dobara try karo — clear face photo lo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _currentStatus = 'NONE'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Dobara Try Karo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Main Form ─────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.face, color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text('Kyun Zaroori Hai?',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
            const SizedBox(height: 10),
            _infoRow(Icons.lock_open,   'P2P jobs apply kar sakte ho'),
            _infoRow(Icons.shield,      'Trusted Driver badge milega'),
            _infoRow(Icons.star,        'Trust score +15 boost'),
            _infoRow(Icons.money_off,   'Bilkul FREE — Aadhaar ki zaroorat nahi'),
          ]),
        ),
        const SizedBox(height: 20),

        // Tips
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.navyLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ACHHI SELFIE KAISE LEN',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            _tipRow('☀️', 'Roshni mein lo — andhera nahi'),
            _tipRow('👤', 'Poora chehra dikhna chahiye'),
            _tipRow('😐', 'Seedha dekho camera mein'),
            _tipRow('🚫', 'Sunglasses ya cap nahi'),
          ]),
        ),
        const SizedBox(height: 24),

        // Selfie preview / placeholder
        GestureDetector(
          onTap: _takeSelfie,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selfieFile != null
                    ? AppTheme.green.withOpacity(0.4)
                    : AppTheme.primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: _selfieFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.file(_selfieFile!, fit: BoxFit.cover),
                      // Retake overlay
                      Positioned(
                        bottom: 10, right: 10,
                        child: GestureDetector(
                          onTap: _takeSelfie,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.refresh, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Retake', style: TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                      // Green checkmark
                      const Positioned(
                        top: 10, right: 10,
                        child: Icon(Icons.check_circle, color: AppTheme.green, size: 28),
                      ),
                    ]),
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.1),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.camera_alt, color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text('Selfie Lene Ke Liye Tap Karo',
                        style: TextStyle(color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Front camera khulega',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ]),
          ),
        ),
        const SizedBox(height: 10),

        // Gallery option
        Center(
          child: TextButton.icon(
            onPressed: _fromGallery,
            icon: const Icon(Icons.photo_library_outlined,
                color: AppTheme.textMuted, size: 16),
            label: const Text('Gallery se choose karo',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),

        // Submit button
        if (_selfieFile != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                disabledBackgroundColor: AppTheme.green.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.upload_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('Submit Karo', style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                    ]),
            ),
          ),

        // Loading message
        if (_loading) ...[
          const SizedBox(height: 10),
          Center(child: Text(_loadingMsg,
              style: const TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.w600))),
        ],

        // Error
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.red.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.red, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_error,
                  style: const TextStyle(color: AppTheme.red, fontSize: 13))),
            ]),
          ),
        ],

        const SizedBox(height: 32),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.navyLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.textMuted, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Selfie sirf verification ke liye use hogi. '
              'Publicly share nahi hogi. Admin review ke baad delete kar di jaayegi.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _tierBadge(String tier, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shield, color: color, size: 16),
        const SizedBox(width: 6),
        Text(tier, style: TextStyle(color: color, fontWeight: FontWeight.w800,
            fontSize: 13, letterSpacing: 1.5, fontFamily: 'Rajdhani')),
        const SizedBox(width: 6),
        const Text('Tier', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, color: AppTheme.primary, size: 14),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ]),
  );

  Widget _tipRow(String emoji, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]),
  );
}
