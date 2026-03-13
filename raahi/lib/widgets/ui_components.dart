// ============================================================
// lib/widgets/ui_components.dart  — Production v3
// Shared premium components used across all screens
// ============================================================
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
// SECTION LABEL
// ═══════════════════════════════════════════════════════════
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(text,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppTheme.textMuted, letterSpacing: 1.5,
          )),
        if (trailing != null) ...[ const Spacer(), trailing! ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PREMIUM CARD
// ═══════════════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.radius = AppTheme.r14,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? AppTheme.cardBg : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppTheme.cardBorder),
        boxShadow: shadow ?? AppTheme.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 120),
        child: card,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PRESSABLE — wraps any widget with tap feedback
// ═══════════════════════════════════════════════════════════
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GLOW BUTTON — primary CTA
// ═══════════════════════════════════════════════════════════
class GlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;
  final double height;
  final double fontSize;
  final double radius;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false,
    this.color,
    this.height = 54,
    this.fontSize = 17,
    this.radius = AppTheme.r14,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppTheme.primary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c, Color.lerp(c, Colors.black, 0.25)!],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: _pressed ? [] : [
              BoxShadow(color: c.withOpacity(0.42), blurRadius: 20, offset: const Offset(0, 7)),
            ],
          ),
          child: widget.isLoading
              ? const Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        color: Colors.white,
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulse;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ] else ...[
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color,
              boxShadow: pulse ? [BoxShadow(color: color.withOpacity(0.7), blurRadius: 5)] : null,
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(label,
          style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROBLEM TILE (for roadside help)
// ═══════════════════════════════════════════════════════════
class ProblemTile extends StatelessWidget {
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  const ProblemTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r14),
          border: Border.all(
            color: selected ? AppTheme.primary.withOpacity(0.7) : AppTheme.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PRICE CHIP
// ═══════════════════════════════════════════════════════════
class PriceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PriceChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.r12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INFO ROW
// ═══════════════════════════════════════════════════════════
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontSize: 13, fontWeight: FontWeight.w600,
          )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DIVIDER
// ═══════════════════════════════════════════════════════════
class AppDivider extends StatelessWidget {
  final EdgeInsets margin;
  const AppDivider({super.key, this.margin = const EdgeInsets.symmetric(vertical: 12)});

  @override
  Widget build(BuildContext context) =>
    Container(margin: margin, height: 1, color: AppTheme.cardBorder);
}

// ═══════════════════════════════════════════════════════════
// SHIMMER BOX (loading placeholder)
// ═══════════════════════════════════════════════════════════
class ShimmerBox extends StatefulWidget {
  final double width, height;
  final double radius;
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 10});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [AppTheme.cardBg, AppTheme.surfaceHigh, AppTheme.cardBg],
          ),
        ),
      ),
    );
  }
}
