// ============================================================
// breakdown_to_mechanics_example.dart
//
// Shows the complete user journey:
//   1. Open BreakdownLocationPickerScreen
//   2. User confirms location → BreakdownRequest returned
//   3. Navigate to MechanicsMapScreen pre-centered on breakdown spot
//
// Copy this pattern into RequestHelpScreen or HomeScreen.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/breakdown_request.dart';
import 'breakdown_location_picker_screen.dart';

// ── Helper function (copy anywhere) ───────────────────────

/// Opens breakdown picker → on confirm, opens mechanics map
/// pre-centered on the confirmed breakdown location.
Future<void> openBreakdownThenMechanics(
  BuildContext context, {
  String initialIssue = '',
}) async {
  // Step 1 — open location picker
  final BreakdownRequest? request = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BreakdownLocationPickerScreen(
        initialIssue: initialIssue),
      fullscreenDialog: true,
    ),
  );

  // Step 2 — if confirmed, open mechanics map with that location
  if (request != null && context.mounted) {
    context.push('/mechanics', extra: request);
  }
}

// ── Example widget using the pattern ──────────────────────

class BreakdownToMechanicsButton extends StatelessWidget {
  final String issue;
  const BreakdownToMechanicsButton({super.key, this.issue = ''});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => openBreakdownThenMechanics(context, initialIssue: issue),
      icon: const Icon(Icons.car_repair_rounded),
      label: const Text('Find Nearby Mechanics'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Usage in RequestHelpScreen (after user confirms job) ───
//
// ElevatedButton(
//   onPressed: () => openBreakdownThenMechanics(
//     context,
//     initialIssue: selectedProblem,
//   ),
//   child: const Text('Set Location & Find Mechanics'),
// ),
//
// ── Usage from AI Results screen ──────────────────────────
//
// GlowButton(
//   label: 'Find Nearby Mechanic',
//   icon: Icons.build_rounded,
//   onTap: () => openBreakdownThenMechanics(
//     context,
//     initialIssue: diagnosedIssue,
//   ),
// ),
