import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    try {
      final res = await SupabaseService.getEarningsDetails();
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF)))
          : RefreshIndicator(
              onRefresh: _fetchEarnings,
              color: const Color(0xFF00D1FF),
              backgroundColor: const Color(0xFF0A1628),
              child: Stack(
                children: [
                  Positioned(top: -100, left: -50, child: _glow(const Color(0xFF0FF4C6), 0.035, 320)),
                  Positioned(bottom: -80, right: -60, child: _glow(const Color(0xFF00D1FF), 0.03, 280)),
                  SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 20),
                        const Text('Earnings', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('Track your income & payouts', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
                        const SizedBox(height: 28),
                        _buildTotalEarningsCard(),
                        const SizedBox(height: 20),
                        _buildWithdrawButton(),
                        const SizedBox(height: 20),
                        _buildPeriodSelector(),
                        const SizedBox(height: 20),
                        _buildWeeklyBreakdown(),
                        const SizedBox(height: 20),
                        _buildPayoutHistory(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalEarningsCard() {
    final total = _data['total'] ?? 0.0;
    final pending = _data['pending'] ?? 0.0;
    final paidOut = _data['paid_out'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF081020)],
        ),
        border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: const Color(0xFF00D1FF).withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Earnings', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF0FF4C6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trendingUp, color: Color(0xFF0FF4C6), size: 14),
                    SizedBox(width: 4),
                    Text('+18%', style: TextStyle(color: Color(0xFF0FF4C6), fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2)),
          const SizedBox(height: 4),
          Text('Updated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat('Pending', '₹${pending.toStringAsFixed(0)}', const Color(0xFFFFD700)),
              const SizedBox(width: 16),
              _buildMiniStat('Paid Out', '₹${paidOut.toStringAsFixed(0)}', const Color(0xFF0FF4C6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton() {
    final pending = _data['pending'] ?? 0.0;
    return GestureDetector(
      onTap: pending > 0 ? () => _showWithdrawDialog(pending) : null,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: pending > 0 ? const Color(0xFF00D1FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pending > 0 ? const Color(0xFF00D1FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            'WITHDRAW EARNINGS', 
            style: TextStyle(
              color: pending > 0 ? const Color(0xFF00D1FF) : Colors.white24, 
              fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1
            )
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(double maxAmount) {
    final controller = TextEditingController(text: maxAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter amount to withdraw (Max: ₹${maxAmount.toInt()})', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Color(0xFF00D1FF), fontSize: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D1FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > maxAmount) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
                return;
              }
              Navigator.pop(context);
              try {
                await SupabaseService.requestPayout(amount);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout request sent!'), backgroundColor: Colors.green));
                   _fetchEarnings();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('WITHDRAW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'All Time'];
    return Row(
      children: periods.map((p) {
        final isSelected = _selectedPeriod == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00D1FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF00D1FF).withValues(alpha: 0.3) : Colors.transparent),
              ),
              child: Text(
                p, textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? const Color(0xFF00D1FF) : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyBreakdown() {
    final weekly = List<double>.from(_data['weekly'] ?? List.filled(7, 0.0));
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    double maxAmount = weekly.fold(0.0, (a, b) => a > b ? a : b);
    if (maxAmount == 0) maxAmount = 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Overview', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final amount = weekly[i];
                final fraction = (amount / maxAmount).clamp(0.0, 1.0);
                final isToday = DateTime.now().weekday - 1 == i;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('₹${amount.toInt()}', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: 28, height: (100 * fraction).clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: isToday
                              ? [const Color(0xFF00D1FF), const Color(0xFF0FF4C6)]
                              : [const Color(0xFF00D1FF).withValues(alpha: 0.3), const Color(0xFF00D1FF).withValues(alpha: 0.1)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(days[i], style: TextStyle(color: isToday ? const Color(0xFF00D1FF) : Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutHistory() {
    final history = List<Map<String, dynamic>>.from(_data['history'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payout History', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (history.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 20),
             child: Center(child: Text('No payout history yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.2)))),
           )
        else
          ...history.map((h) => _buildPayoutItem(h['method'] ?? 'Payout', '₹${(h['amount'] as double).toInt()}', _formatDate(h['date']), true)).toList(),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildPayoutItem(String method, String amount, String date, bool success) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFF0FF4C6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(LucideIcons.banknote, color: Color(0xFF0FF4C6), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(color: Color(0xFF0FF4C6), fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}
