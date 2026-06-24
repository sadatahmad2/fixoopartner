import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'dart:ui';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await SupabaseService.getPartnerBookings(status: 'Completed');
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Job History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _glow(const Color(0xFF00D1FF), 0.03, 250)),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF)))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _history.length,
                      itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 60, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Text('No history found', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job['service_name'] ?? 'Service', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('₹${job['price'] ?? 0}', style: const TextStyle(color: Color(0xFF0FF4C6), fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text(job['brand'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 6),
              Text(job['scheduled_date'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0FF4C6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('COMPLETED', style: TextStyle(color: Color(0xFF0FF4C6), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
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
