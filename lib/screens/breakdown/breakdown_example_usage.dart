// ============================================================
// lib/screens/breakdown/breakdown_example_usage.dart
//
// EXAMPLE USAGE — how any screen in the app can open the
// BreakdownLocationPickerScreen and receive confirmed coordinates.
//
// This file is for reference only. Do NOT add it to routing.
// Copy the pattern you need into whatever screen calls the picker.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/breakdown_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components.dart';
import 'breakdown_location_picker_screen.dart';

// ════════════════════════════════════════════════════════════
// PATTERN A — Direct Navigator.push  (no go_router needed)
// Use this when you already have a BuildContext and want the
// result back as a return value, e.g. from RequestHelpScreen.
// ════════════════════════════════════════════════════════════

/// Opens the picker and waits for the user to confirm a location.
/// Returns a [BreakdownRequest] or null if the user cancelled.
///
/// ```dart
/// final request = await openBreakdownPicker(
///   context,
///   initialIssue: 'Engine overheating',
/// );
/// if (request != null) {
///   // send to backend
///   ApiService().createBreakdownRequest(request.toJson());
/// }
/// ```
Future<BreakdownRequest?> openBreakdownPicker(
  BuildContext context, {
  String initialIssue = '',
}) {
  return Navigator.of(context).push<BreakdownRequest>(
    MaterialPageRoute(
      builder: (_) => BreakdownLocationPickerScreen(
        initialIssue: initialIssue,
      ),
      fullscreenDialog: true,
    ),
  );
}

// ════════════════════════════════════════════════════════════
// PATTERN B — go_router  (if you prefer the app router)
// Push the '/breakdown-location' route with optional extra.
// ════════════════════════════════════════════════════════════

/// Push via go_router.
/// Extra is the issue description string.
///
/// ```dart
/// context.push('/breakdown-location', extra: 'Tyre puncture');
/// ```
///
/// To receive the result with go_router you need a callback or
/// Riverpod state. For simplicity Pattern A is recommended.

// ════════════════════════════════════════════════════════════
// FULL DEMO WIDGET — shows both patterns in a runnable widget
// ════════════════════════════════════════════════════════════

class BreakdownPickerDemoScreen extends StatefulWidget {
  const BreakdownPickerDemoScreen({super.key});

  @override
  State<BreakdownPickerDemoScreen> createState() =>
      _BreakdownPickerDemoScreenState();
}

class _BreakdownPickerDemoScreenState
    extends State<BreakdownPickerDemoScreen> {
  BreakdownRequest? _lastRequest;
  bool _sending = false;

  // ── Open picker (Pattern A) ────────────────────────────────
  Future<void> _openPicker() async {
    final request = await openBreakdownPicker(
      context,
      initialIssue: 'Tyre puncture on NH-44',
    );

    if (request != null && mounted) {
      setState(() => _lastRequest = request);

      // ── What you'd do next ─────────────────────────────────
      // 1. Show confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.cardBg,
          content: Text(
            'Location set: ${request.latitude.toStringAsFixed(4)}, '
            '${request.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );

      // 2. Send to backend (uncomment when ready):
      // await ApiService().createBreakdownRequest(request.toJson());
    }
  }

  // ── Simulate send ──────────────────────────────────────────
  Future<void> _sendToBackend() async {
    if (_lastRequest == null) return;
    setState(() => _sending = true);

    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Breakdown request sent to backend!'),
          backgroundColor: AppTheme.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        title: const Text('Breakdown Picker Demo',
          style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Request summary card ───────────────────────────
          if (_lastRequest != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.r14),
                border: Border.all(color: AppTheme.green.withOpacity(0.35)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.green, size: 18),
                    const SizedBox(width: 8),
                    const Text('Location Confirmed',
                      style: TextStyle(color: AppTheme.green,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  _Row('Latitude',  _lastRequest!.latitude.toStringAsFixed(6)),
                  _Row('Longitude', _lastRequest!.longitude.toStringAsFixed(6)),
                  _Row('Issue',     _lastRequest!.issueDescription),
                  _Row('Time',      _lastRequest!.timestamp
                      .toLocal().toString().substring(0, 19)),
                  const SizedBox(height: 12),
                  // JSON preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _prettyJson(_lastRequest!.toJson()),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                        fontSize: 11, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // ── Placeholder card ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.r14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(children: [
                const Icon(Icons.map_outlined,
                    color: AppTheme.textMuted, size: 40),
                const SizedBox(height: 12),
                const Text('No location selected yet',
                  style: TextStyle(color: AppTheme.textMuted,
                      fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Tap the button below to open the map picker',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          const Spacer(),

          // ── Send to backend ────────────────────────────────
          if (_lastRequest != null) ...[
            GlowButton(
              label: 'Send Breakdown Request',
              icon: Icons.send_rounded,
              height: 54, fontSize: 16, radius: AppTheme.r14,
              color: AppTheme.green,
              isLoading: _sending,
              onTap: _sendToBackend,
            ),
            const SizedBox(height: 10),
          ],

          // ── Open picker ────────────────────────────────────
          GlowButton(
            label: _lastRequest == null
                ? 'Set Breakdown Location'
                : 'Change Location',
            icon: Icons.my_location_rounded,
            height: 56, fontSize: 17, radius: AppTheme.r16,
            onTap: _openPicker,
          ),

          const SizedBox(height: 8),

          const Text(
            'This demo shows Pattern A: Navigator.push + await',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> m) {
    final sb = StringBuffer('{\n');
    m.forEach((k, v) => sb.writeln('  "$k": "$v",'));
    sb.write('}');
    return sb.toString();
  }
}

// ── Helper row widget ──────────────────────────────────────
class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80,
          child: Text(label,
            style: const TextStyle(color: AppTheme.textMuted,
                fontSize: 12, fontWeight: FontWeight.w500))),
        const Text(' : ',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Expanded(child: Text(value,
          style: const TextStyle(color: AppTheme.textPrimary,
              fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
