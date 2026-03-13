import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ===================== SUBSCRIPTION SCREEN =====================
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Pro Subscription'), backgroundColor: AppTheme.navyLight),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.saffron.withOpacity(0.15), AppTheme.navy],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppTheme.yellow, size: 48),
                  SizedBox(height: 12),
                  Text('Mechanic Pro Plan', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  SizedBox(height: 8),
                  Text('Zyada leads, zyada kamai', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan cards
            _PlanCard(
              tier: 'Basic', priceMonthly: '₹999', priceYearly: '₹9,999',
              color: AppTheme.cyan,
              features: ['5 Leads per month', 'Verified badge', 'Search listing', 'Basic analytics'],
            ),
            const SizedBox(height: 16),
            _PlanCard(
              tier: 'Pro', priceMonthly: '₹2,499', priceYearly: '₹24,999',
              color: AppTheme.yellow,
              isRecommended: true,
              features: [
                'Unlimited leads', 'Priority listing (TOP)',
                'P2P job first notifications', 'Advanced analytics',
                'WhatsApp integration', 'Free profile verification',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String tier, priceMonthly, priceYearly;
  final Color color;
  final List<String> features;
  final bool isRecommended;

  const _PlanCard({
    required this.tier, required this.priceMonthly, required this.priceYearly,
    required this.color, required this.features, this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRecommended ? color : AppTheme.cardBorder, width: isRecommended ? 2 : 1),
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text('⭐ RECOMMENDED', textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier, style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(priceMonthly,
                            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('/month', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: color, size: 16),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.9)),
                    child: Text('$tier Plan Lo', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MECHANIC REGISTER SCREEN ====================
class MechanicRegisterScreen extends StatefulWidget {
  const MechanicRegisterScreen({super.key});

  @override
  State<MechanicRegisterScreen> createState() => _MechanicRegisterScreenState();
}

class _MechanicRegisterScreenState extends State<MechanicRegisterScreen> {
  final _shopCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final List<String> _selectedSpecs = [];
  bool _isMobile = false;

  final _specs = ['Puncture', 'Engine', 'AC', 'Battery', 'Brakes', 'Towing', 'Electrical', 'Body Work'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Mechanic Register Karo'), backgroundColor: AppTheme.navyLight),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apni Workshop Register Karo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('Aur highway drivers se directly leads pao!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 28),

            _label('Workshop/Shop Ka Naam *'),
            const SizedBox(height: 8),
            TextField(controller: _shopCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Ram Ji Auto Works')),
            const SizedBox(height: 20),

            _label('Address *'),
            const SizedBox(height: 8),
            TextField(controller: _addrCtrl, maxLines: 2,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'NH-44, Near Petrol Pump, Nagpur')),
            const SizedBox(height: 20),

            _label('Contact Number *'),
            const SizedBox(height: 8),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(prefixText: '+91 ', hintText: '98765 43210')),
            const SizedBox(height: 20),

            _label('Kya Karte Ho? (Select all that apply)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _specs.map((s) {
                final sel = _selectedSpecs.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: sel,
                  onSelected: (v) => setState(() => v ? _selectedSpecs.add(s) : _selectedSpecs.remove(s)),
                  selectedColor: AppTheme.saffron.withOpacity(0.2),
                  checkmarkColor: AppTheme.saffron,
                  backgroundColor: AppTheme.cardBg,
                  labelStyle: TextStyle(color: sel ? AppTheme.saffron : AppTheme.textSecondary, fontSize: 12),
                  side: BorderSide(color: sel ? AppTheme.saffron : AppTheme.cardBorder),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Mobile mechanic toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile Mechanic', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        Text('Driver ke paas jaake help karta hoon', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(value: _isMobile, onChanged: (v) => setState(() => _isMobile = v),
                      activeColor: AppTheme.saffron),
                ],
              ),
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Register Karo! 🔧',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Register hone ke baad verify kiya jaayega (24-48 hours)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
}
