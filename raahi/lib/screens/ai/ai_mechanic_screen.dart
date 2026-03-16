// ============================================================
// lib/screens/ai/ai_mechanic_screen.dart  — Production v4
// 3-step flow: Input → Processing → Results
// Smooth fade/slide transitions between steps
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/rewarded_ai_widget.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/ui_components.dart';

// ── Step enum ─────────────────────────────────────────────────
enum _Step { input, processing, result }

// ── Urgency levels ────────────────────────────────────────────
enum _Urgency { low, medium, high }

// ── Result model ─────────────────────────────────────────────
class _DiagResult {
  final String possibleIssue;
  final _Urgency urgency;
  final String suggestedFix;
  const _DiagResult({
    required this.possibleIssue,
    required this.urgency,
    required this.suggestedFix,
  });
}

class AiMechanicScreen extends StatefulWidget {
  const AiMechanicScreen({super.key});
  @override
  State<AiMechanicScreen> createState() => _AiMechanicScreenState();
}

class _AiMechanicScreenState extends State<AiMechanicScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.input;
  _DiagResult? _result;

  // Step 1 state
  final _textCtrl = TextEditingController();
  final _speech = SpeechToText();
  final _tts = FlutterTts();
  final _lang = LanguageService();
  bool _isListening = false;
  bool _speechAvailable = false;
  int _freeMessages = 5;
  bool _showRewardedButton = false;
  bool _hasError = false;
  String _errorMsg = '';
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  // Processing animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _spinCtrl;

  // Mic pulse
  late AnimationController _micCtrl;

  // Result card stagger
  late List<AnimationController> _resultCtrls;
  late List<Animation<double>> _resultFades;
  late List<Animation<Offset>> _resultSlides;

  // Screen transition
  late AnimationController _transCtrl;
  late Animation<double> _transAnim;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _lang.addListener(_onLangChanged);

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _spinCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();

    _micCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat(reverse: true);

    // 3 result cards
    _resultCtrls = List.generate(3, (i) => AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300)));
    _resultFades = _resultCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
    _resultSlides = _resultCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();

    _transCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 280));
    _transAnim = CurvedAnimation(parent: _transCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _lang.removeListener(_onLangChanged);
    _textCtrl.dispose();
    _speech.cancel(); _tts.stop();
    _pulseCtrl.dispose(); _spinCtrl.dispose(); _micCtrl.dispose();
    for (final c in _resultCtrls) c.dispose();
    _transCtrl.dispose();
    super.dispose();
  }

  void _onLangChanged() { _initTts(); setState(() {}); }
  Future<void> _initTts() async {
    await _tts.setLanguage(_lang.currentLocale);
    await _tts.setSpeechRate(0.85);
  }
  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
        onError: (_) => setState(() => _isListening = false));
    setState(() {});
  }

  // ── Voice toggle ──────────────────────────────────────────
  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    await _tts.stop();
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (r) {
        if (r.finalResult) {
          setState(() {
            _isListening = false;
            _textCtrl.text = r.recognizedWords;
          });
        }
      },
      localeId: _lang.currentLocale.replaceAll('-', '_'),
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: false,
    );
  }

  // ── Analyze → step 2 → step 3 ────────────────────────────
    Future<void> _analyze() async {
      final text = _textCtrl.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please describe your car problem first')));
        return;
      }
      if (_freeMessages <= 0) {
        setState(() => _showRewardedButton = true);
        return;
      }
      _freeMessages--;

      // Transition → processing
      await _transCtrl.forward();
      setState(() => _step = _Step.processing);
      _transCtrl.reverse();

      try {
        final reply = await _callBackend(text);

        // Parse response into structured result
        final result = _DiagResult(
          possibleIssue: _extractSection(reply, 'issue') ?? reply,
          urgency: _extractUrgency(reply),
          suggestedFix: _extractSection(reply, 'fix') ?? 'Consult a mechanic for further inspection.',
        );

        // Transition → result
        await _transCtrl.forward();
        setState(() { _step = _Step.result; _result = result; });
        _transCtrl.reverse();

        // Stagger result cards
        for (int i = 0; i < 3; i++) {
          await Future.delayed(Duration(milliseconds: 80 + i * 150));
          if (mounted) _resultCtrls[i].forward();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _step = _Step.input;
            _hasError = true;
            _errorMsg = 'Network error. Internet connection check karo aur dobara try karo.';
          });
        }
      }
    }

    // ── Backend call with Gemini fallback ─────────────────────
    Future<String> _callBackend(String message) async {
      try {
        final response = await http.post(
          Uri.parse('https://web-production-e6c90c.up.railway.app/api/v1/ai/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'language': 'hi',
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data['reply'] as String? ?? 'कोई जवाब नहीं मिला';
        }
        // Non-200 — fall through to Gemini
        return await _callGeminiDirect(message);
      } catch (e) {
        // Timeout / network error — fall through to Gemini
        return await _callGeminiDirect(message);
      }
    }

    // ── Direct Gemini fallback ─────────────────────────────────
    Future<String> _callGeminiDirect(String message) async {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'
          '?key=AIzaSyC0hmuQibdcPsQStTyofhhHw86HWs4ZD7k',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are Raahi AI mechanic. Answer in Hindi. User says: $message'
                }
              ]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      throw Exception('Both services failed: ${response.statusCode}');
    }

  
  String? _extractSection(String text, String key) {
    final lines = text.split('\n');
    if (key == 'issue') {
      final match = lines.firstWhere(
          (l) => l.toLowerCase().contains('issue') || l.toLowerCase().contains('problem'),
          orElse: () => '');
      return match.isNotEmpty ? match.replaceAll(RegExp(r'[*#•\-]'), '').trim() : null;
    }
    if (key == 'fix') {
      final match = lines.firstWhere(
          (l) => l.toLowerCase().contains('action') ||
              l.toLowerCase().contains('fix') ||
              l.toLowerCase().contains('suggest'),
          orElse: () => '');
      return match.isNotEmpty ? match.replaceAll(RegExp(r'[*#•\-]'), '').trim() : null;
    }
    return null;
  }

  _Urgency _extractUrgency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('immediate') || lower.contains('urgent') ||
        lower.contains('stop') || lower.contains('danger') ||
        lower.contains('turant')) return _Urgency.high;
    if (lower.contains('soon') || lower.contains('check') ||
        lower.contains('monitor')) return _Urgency.medium;
    return _Urgency.low;
  }

  void _reset() {
    for (final c in _resultCtrls) c.reset();
    setState(() { _step = _Step.input; _result = null; _hasError = false; _errorMsg = ''; });
  }

  List<String> get _suggestions => const [
    'Tyre puncture ho gaya',
    'Engine heat ho raha hai',
    'Battery down hai',
    'Petrol khatam',
    'Brake problem',
    'AC kaam nahi kar raha',
  ];

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _transAnim.drive(Tween(begin: 1, end: 0)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: switch (_step) {
            _Step.input      => _buildInputStep(),
            _Step.processing => _buildProcessingStep(),
            _Step.result     => _buildResultStep(),
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.navyLight,
      titleSpacing: 0,
      leading: _step != _Step.input
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _reset)
          : null,
      title: Row(children: [
        if (_step == _Step.input) ...[
          Container(width: 34, height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
        ],
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(switch (_step) {
            _Step.input      => 'AI Mechanic',
            _Step.processing => 'Analyzing...',
            _Step.result     => 'Diagnosis Result',
          }, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Row(children: [
            Container(width: 6, height: 6,
              decoration: const BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.green)),
            const SizedBox(width: 5),
            Text('Online · ${_lang.currentLanguage.displayName}',
              style: const TextStyle(color: AppTheme.green, fontSize: 10,
                  fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
      actions: [
        // Free messages
        Container(
          margin: const EdgeInsets.only(right: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withOpacity(0.25))),
          child: Text('$_freeMessages left',
            style: const TextStyle(color: AppTheme.primary,
                fontSize: 11, fontWeight: FontWeight.w700))),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 1 — INPUT
  // ══════════════════════════════════════════════════════════
  Widget _buildInputStep() {
    return Column(
      key: const ValueKey('input'),
      children: [
        // Step indicator
        _buildStepIndicator(1),

        // Error banner with retry
        if (_hasError)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.red.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.wifi_off_rounded, color: AppTheme.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_errorMsg,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
              ),
              TextButton(
                onPressed: () { setState(() => _hasError = false); _analyze(); },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),

        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Large text input card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.r16),
                border: Border.all(
                  color: _isListening
                      ? AppTheme.red.withOpacity(0.5) : AppTheme.cardBorder,
                  width: _isListening ? 1.5 : 1)),
              child: Column(children: [
                // Input area
                TextField(
                  controller: _textCtrl,
                  maxLines: 6, minLines: 5,
                  style: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 15, height: 1.6),
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? '🎙️ Listening... speak now'
                        : 'Describe your car problem...\n\ne.g. "Engine is overheating when AC is on"',
                    hintStyle: TextStyle(
                      color: _isListening
                          ? AppTheme.red.withOpacity(0.6) : AppTheme.textMuted,
                      fontSize: 13, height: 1.7),
                    filled: false, border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                // Bottom: char count + mic
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.cardBorder))),
                  child: Row(children: [
                    ValueListenableBuilder(
                      valueListenable: _textCtrl,
                      builder: (_, val, __) => Text('${val.text.length} chars',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11))),
                    const Spacer(),
                    if (_speechAvailable)
                      AnimatedBuilder(
                        animation: _micCtrl,
                        builder: (_, __) => Pressable(
                          onTap: _toggleVoice,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? AppTheme.red.withOpacity(0.08 + 0.08 * _micCtrl.value)
                                  : AppTheme.surfaceHigh,
                              border: Border.all(
                                color: _isListening ? AppTheme.red : AppTheme.cardBorder,
                                width: _isListening ? 1.5 : 1)),
                            child: Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: _isListening ? AppTheme.red : AppTheme.textMuted,
                              size: 18)),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // Primary button
            GlowButton(
              label: 'Analyze Problem',
              icon: Icons.search_rounded,
              height: 56, fontSize: 18, radius: AppTheme.r16,
              onTap: _analyze,
            ),

            if (_showRewardedButton) ...[
              const SizedBox(height: 12),
              RewardedAiButton(onUnlocked: () {
                setState(() { _freeMessages = 5; _showRewardedButton = false; });
                AdService().loadRewarded();
              }),
            ],

            const SizedBox(height: 24),

            // Quick suggestions
            Align(alignment: Alignment.centerLeft,
              child: const SectionLabel('TRY THESE')),
            Wrap(spacing: 8, runSpacing: 8,
              children: _suggestions.map((s) => Pressable(
                onTap: () => setState(() => _textCtrl.text = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder)),
                  child: Text(s, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12,
                    fontWeight: FontWeight.w500))),
              )).toList()),
          ]),
        )),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 2 — PROCESSING
  // ══════════════════════════════════════════════════════════
  Widget _buildProcessingStep() {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated ring
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child),
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.08),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3), width: 2)),
                child: Stack(alignment: Alignment.center, children: [
                  // Spinning ring
                  AnimatedBuilder(
                    animation: _spinCtrl,
                    builder: (_, child) => Transform.rotate(
                      angle: _spinCtrl.value * 6.28,
                      child: child),
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.transparent, width: 3,
                          strokeAlign: BorderSide.strokeAlignCenter),
                        gradient: SweepGradient(
                          colors: [AppTheme.primary, Colors.transparent]),
                      ),
                    ),
                  ),
                  // Center icon
                  Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 32)),
                ]),
              ),
            ),

            const SizedBox(height: 36),

            // Pulsing text
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: 0.6 + 0.4 * _pulseAnim.value,
                child: const Text('Analyzing your car problem...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20,
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
            ),

            const SizedBox(height: 10),

            Text('Raahi AI is diagnosing in ${_lang.currentLanguage.displayName}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),

            const SizedBox(height: 40),

            // Progress dots
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) {
                  final phase = ((_spinCtrl.value * 3) - i).abs();
                  final active = phase < 0.5 || phase > 2.5;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 10 : 7,
                    height: active ? 10 : 7,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppTheme.primary : AppTheme.textMuted));
                }))),

            const SizedBox(height: 40),

            // What we check
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.r14),
                border: Border.all(color: AppTheme.cardBorder)),
              child: Column(children: [
                _ProcessItem('🔍 Identifying possible issues'),
                _ProcessItem('⚠️ Assessing urgency level'),
                _ProcessItem('🔧 Finding suggested fixes'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STEP 3 — RESULT
  // ══════════════════════════════════════════════════════════
  Widget _buildResultStep() {
    if (_result == null) return const SizedBox.shrink();
    final r = _result!;

    final urgencyData = switch (r.urgency) {
      _Urgency.high   => (label: 'HIGH — Stop driving now', color: AppTheme.red,
          icon: Icons.warning_amber_rounded),
      _Urgency.medium => (label: 'MEDIUM — Check soon', color: AppTheme.yellow,
          icon: Icons.info_outline_rounded),
      _Urgency.low    => (label: 'LOW — Monitor it', color: AppTheme.green,
          icon: Icons.check_circle_outline_rounded),
    };

    return Column(
      key: const ValueKey('result'),
      children: [
        _buildStepIndicator(3),
        Expanded(child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Card 1 — Possible Issue
            _ResultCard(
              index: 0,
              fadeAnim: _resultFades[0],
              slideAnim: _resultSlides[0],
              accentColor: AppTheme.cyan,
              icon: Icons.search_rounded,
              title: 'Possible Issue',
              child: Text(r.possibleIssue,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 14, height: 1.6)),
            ),

            const SizedBox(height: 12),

            // Card 2 — Urgency
            _ResultCard(
              index: 1,
              fadeAnim: _resultFades[1],
              slideAnim: _resultSlides[1],
              accentColor: urgencyData.color,
              icon: urgencyData.icon,
              title: 'Urgency Level',
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: urgencyData.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(urgencyData.icon, color: urgencyData.color, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(urgencyData.label,
                      style: TextStyle(color: urgencyData.color,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(switch (r.urgency) {
                      _Urgency.high   => 'Do not continue driving. Seek help immediately.',
                      _Urgency.medium => 'Schedule a mechanic visit within 1–2 days.',
                      _Urgency.low    => 'Keep monitoring. Visit mechanic at next service.',
                    }, style: const TextStyle(color: AppTheme.textMuted,
                        fontSize: 12, height: 1.4)),
                  ])),
              ]),
            ),

            const SizedBox(height: 12),

            // Card 3 — Suggested Fix
            _ResultCard(
              index: 2,
              fadeAnim: _resultFades[2],
              slideAnim: _resultSlides[2],
              accentColor: AppTheme.green,
              icon: Icons.build_circle_rounded,
              title: 'Suggested Fix',
              child: Text(r.suggestedFix,
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 14, height: 1.6)),
            ),

            const SizedBox(height: 24),

            // Action buttons
            FadeTransition(
              opacity: _resultFades[2],
              child: Column(children: [
                GlowButton(
                  label: 'Find Nearby Mechanic',
                  icon: Icons.build_rounded,
                  height: 56, fontSize: 17, radius: AppTheme.r16,
                  color: AppTheme.cyan,
                  onTap: () => context.go('/mechanics'),
                ),
                const SizedBox(height: 10),
                GlowButton(
                  label: 'Request Roadside Help',
                  icon: Icons.emergency_rounded,
                  height: 56, fontSize: 17, radius: AppTheme.r16,
                  color: AppTheme.primary,
                  onTap: () => context.go('/request-help'),
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: _reset,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.r14),
                      border: Border.all(color: AppTheme.cardBorder)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded, color: AppTheme.textMuted, size: 18),
                        SizedBox(width: 8),
                        Text('Diagnose another problem',
                          style: TextStyle(color: AppTheme.textSecondary,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ]),
        )),
      ],
    );
  }

  // ── Step Indicator ────────────────────────────────────────
  Widget _buildStepIndicator(int current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.navyLight,
      child: Row(children: List.generate(3, (i) {
        final num = i + 1;
        final done = num < current;
        final active = num == current;
        final labels = ['Describe', 'Analyzing', 'Results'];
        return Expanded(child: Row(children: [
          // Circle
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppTheme.green
                  : active ? AppTheme.primary : AppTheme.surfaceHigh,
              border: Border.all(
                color: done ? AppTheme.green
                    : active ? AppTheme.primary : AppTheme.cardBorder)),
            child: Center(child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text('$num',
                    style: TextStyle(
                      fontFamily: 'Rajdhani', fontSize: 12, fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.textMuted)))),
          const SizedBox(width: 6),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels[i],
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? AppTheme.textPrimary : AppTheme.textMuted)),
              if (i < 2)
                Container(margin: const EdgeInsets.only(top: 2),
                  height: 1.5,
                  color: done ? AppTheme.green.withOpacity(0.5) : AppTheme.cardBorder),
            ])),
        ]));
      })),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Result Card with stagger animation
// ═══════════════════════════════════════════════════════════
class _ResultCard extends StatelessWidget {
  final int index;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Color accentColor;
  final IconData icon;
  final String title;
  final Widget child;

  const _ResultCard({
    required this.index,
    required this.fadeAnim,
    required this.slideAnim,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.r16),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.07),
                border: Border(
                    bottom: BorderSide(color: accentColor.withOpacity(0.2))),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.r16))),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accentColor, size: 16)),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(
                  fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.w700,
                  color: accentColor, letterSpacing: 0.3)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Processing item row
// ═══════════════════════════════════════════════════════════
class _ProcessItem extends StatelessWidget {
  final String text;
  const _ProcessItem(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(width: 6, height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppTheme.primary)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 13, fontWeight: FontWeight.w500)),
    ]));
}
