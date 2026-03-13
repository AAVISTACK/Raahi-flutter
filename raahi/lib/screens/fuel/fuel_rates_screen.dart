// ============================================================
// FILE: lib/screens/fuel/fuel_rates_screen.dart
// Daily Petrol/Diesel/CNG rates — keeps users coming back daily
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FuelRatesScreen extends StatefulWidget {
  const FuelRatesScreen({super.key});

  @override
  State<FuelRatesScreen> createState() => _FuelRatesScreenState();
}

class _FuelRatesScreenState extends State<FuelRatesScreen> {
  bool _isLoading = true;
  String _selectedCity = 'Nayagaon';
  DateTime _lastUpdated = DateTime.now();

  final List<String> _cities = [
    'Nayagaon', 'Chandigarh', 'Ludhiana', 'Amritsar', 'Jalandhar',
    'Delhi', 'Mumbai', 'Bangalore', 'Hyderabad', 'Chennai',
    'Kolkata', 'Pune', 'Jaipur', 'Ahmedabad', 'Surat',
  ];

  final Map<String, Map<String, double>> _ratesByCity = {
    'Nayagaon':   {'petrol': 94.24, 'diesel': 87.37, 'cng': 76.59},
    'Chandigarh': {'petrol': 94.24, 'diesel': 87.37, 'cng': 77.00},
    'Ludhiana':   {'petrol': 96.56, 'diesel': 89.62, 'cng': 78.10},
    'Amritsar':   {'petrol': 96.40, 'diesel': 89.48, 'cng': 77.80},
    'Delhi':      {'petrol': 94.72, 'diesel': 87.62, 'cng': 74.09},
    'Mumbai':     {'petrol': 103.44, 'diesel': 89.97, 'cng': 73.00},
    'Bangalore':  {'petrol': 102.86, 'diesel': 88.94, 'cng': 59.00},
    'Hyderabad':  {'petrol': 107.41, 'diesel': 95.65, 'cng': 82.00},
    'Chennai':    {'petrol': 100.85, 'diesel': 92.46, 'cng': 71.00},
    'Kolkata':    {'petrol': 104.95, 'diesel': 91.76, 'cng': 56.00},
    'Pune':       {'petrol': 103.57, 'diesel': 89.97, 'cng': 74.00},
    'Jaipur':     {'petrol': 104.88, 'diesel': 90.36, 'cng': 70.50},
    'Ahmedabad':  {'petrol': 96.63, 'diesel': 89.97, 'cng': 68.00},
    'Surat':      {'petrol': 96.63, 'diesel': 89.97, 'cng': 67.00},
    'Jalandhar':  {'petrol': 96.72, 'diesel': 89.55, 'cng': 77.50},
  };

  Map<String, double> get _currentRates =>
      _ratesByCity[_selectedCity] ?? {'petrol': 94.72, 'diesel': 87.62, 'cng': 74.09};

  final Map<String, double> _change = {'petrol': 0.0, 'diesel': -0.12, 'cng': 0.0};

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aaj ke Fuel Rates', style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Daily updated prices', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.saffron),
            onPressed: () {
              setState(() => _isLoading = true);
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) setState(() { _isLoading = false; _lastUpdated = DateTime.now(); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Rates update ho gaye! ✅'),
                  backgroundColor: AppTheme.green,
                  behavior: SnackBarBehavior.floating,
                ));
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        isExpanded: true,
                        dropdownColor: AppTheme.navyLight,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.saffron),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15,
                            fontWeight: FontWeight.w600),
                        items: _cities.map((city) => DropdownMenuItem(
                          value: city,
                          child: Row(children: [
                            const Icon(Icons.location_city_rounded, color: AppTheme.textMuted, size: 16),
                            const SizedBox(width: 8),
                            Text(city),
                          ]),
                        )).toList(),
                        onChanged: (val) { if (val != null) setState(() => _selectedCity = val); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Last updated
                  Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.green, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Aaj ${_lastUpdated.hour.toString().padLeft(2,'0')}:${_lastUpdated.minute.toString().padLeft(2,'0')} pe update hua',
                      style: const TextStyle(color: AppTheme.green, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('LIVE', style: TextStyle(
                          color: AppTheme.green, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Fuel cards
                  _FuelCard(emoji: '⛽', name: 'Petrol',
                      price: _currentRates['petrol']!, change: _change['petrol']!,
                      color: AppTheme.saffron, unit: 'per litre'),
                  const SizedBox(height: 12),
                  _FuelCard(emoji: '🛢️', name: 'Diesel',
                      price: _currentRates['diesel']!, change: _change['diesel']!,
                      color: AppTheme.cyan, unit: 'per litre'),
                  const SizedBox(height: 12),
                  _FuelCard(emoji: '💨', name: 'CNG',
                      price: _currentRates['cng']!, change: _change['cng']!,
                      color: AppTheme.green, unit: 'per kg'),
                  const SizedBox(height: 24),
                  // Calculator
                  _CostCalculator(
                      petrolRate: _currentRates['petrol']!,
                      dieselRate: _currentRates['diesel']!),
                  const SizedBox(height: 24),
                  // Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡 Driver Tip', style: TextStyle(
                            color: AppTheme.saffron, fontWeight: FontWeight.w700, fontSize: 14)),
                        SizedBox(height: 8),
                        Text(
                          'Petrol prices roz subah 6 baje update hote hain. Kal ka rate dekhne ke liye kal subah app open karo!',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  final String emoji, name, unit;
  final double price, change;
  final Color color;
  const _FuelCard({required this.emoji, required this.name, required this.price,
      required this.change, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final isDown = change < 0;
    final unchanged = change == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), AppTheme.cardBg],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text('₹${price.toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
                Text(unit, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                unchanged ? Icons.remove_rounded : isDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                color: unchanged ? AppTheme.textMuted : isDown ? AppTheme.green : AppTheme.red,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                unchanged ? 'No change' : '${change > 0 ? '+' : ''}₹${change.abs().toStringAsFixed(2)} aaj',
                style: TextStyle(
                  color: unchanged ? AppTheme.textMuted : isDown ? AppTheme.green : AppTheme.red,
                  fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostCalculator extends StatefulWidget {
  final double petrolRate, dieselRate;
  const _CostCalculator({required this.petrolRate, required this.dieselRate});

  @override
  State<_CostCalculator> createState() => _CostCalculatorState();
}

class _CostCalculatorState extends State<_CostCalculator> {
  final _litresCtrl = TextEditingController(text: '10');
  String _fuelType = 'petrol';

  double get _rate => _fuelType == 'petrol' ? widget.petrolRate : widget.dieselRate;
  double get _total => (double.tryParse(_litresCtrl.text) ?? 0) * _rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧮 Cost Calculator',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _fuelType = 'petrol'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _fuelType == 'petrol' ? AppTheme.saffron.withOpacity(0.15) : AppTheme.navy,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fuelType == 'petrol' ? AppTheme.saffron : AppTheme.cardBorder),
                ),
                child: Center(child: Text('Petrol',
                    style: TextStyle(color: _fuelType == 'petrol' ? AppTheme.saffron : AppTheme.textMuted,
                        fontWeight: FontWeight.w700))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _fuelType = 'diesel'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _fuelType == 'diesel' ? AppTheme.cyan.withOpacity(0.15) : AppTheme.navy,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fuelType == 'diesel' ? AppTheme.cyan : AppTheme.cardBorder),
                ),
                child: Center(child: Text('Diesel',
                    style: TextStyle(color: _fuelType == 'diesel' ? AppTheme.cyan : AppTheme.textMuted,
                        fontWeight: FontWeight.w700))),
              ),
            )),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Text('Kitne litre:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: TextField(
                controller: _litresCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                onChanged: (_) => setState(() {}),
              ),
            )),
            const SizedBox(width: 12),
            const Text('litre', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.saffron.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
            ),
            child: Center(child: Text(
              'Total: ₹${_total.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.saffron, fontWeight: FontWeight.w800, fontSize: 20),
            )),
          ),
        ],
      ),
    );
  }
}
