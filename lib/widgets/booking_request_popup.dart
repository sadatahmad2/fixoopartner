import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'dart:ui';
import 'dart:async';

class BookingRequestPopup extends StatefulWidget {
  final Map<String, dynamic> booking;
  final double? partnerLat;
  final double? partnerLng;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const BookingRequestPopup({
    super.key,
    required this.booking,
    this.partnerLat,
    this.partnerLng,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<BookingRequestPopup> createState() => _BookingRequestPopupState();
}

class _BookingRequestPopupState extends State<BookingRequestPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  
  double _distance = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacityAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _calculateDistance();
  }

  void _calculateDistance() {
    if (widget.partnerLat != null && widget.partnerLng != null && 
        widget.booking['latitude'] != null && widget.booking['longitude'] != null) {
      final d = SupabaseService.calculateDistance(
        widget.partnerLat!,
        widget.partnerLng!,
        widget.booking['latitude'] as double,
        widget.booking['longitude'] as double,
      );
      setState(() => _distance = d / 1000); // Convert to km
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.acceptBooking(widget.booking['id'].toString());
      widget.onAccept();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.rejectBooking(widget.booking['id']);
      widget.onReject();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1C),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00D1FF).withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildBody(),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00D1FF).withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sparkles, color: Color(0xFF00D1FF), size: 20),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEW BOOKING', style: TextStyle(color: Color(0xFF00D1FF), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text('Incoming Request', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, color: Colors.amber, size: 14),
                const SizedBox(width: 5),
                Text('Just Now', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final problems = widget.booking['problems'] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Service Detail
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.wrench, color: Color(0xFF00D1FF)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.booking['service_name'] ?? 'General Service', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(widget.booking['brand'] ?? 'Multi-brand', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                    ],
                  ),
                ),
                Text('₹${widget.booking['price'] ?? '0'}', style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Location & Distance
          Row(
            children: [
              _buildInfoChip(LucideIcons.mapPin, widget.booking['address'] ?? 'Near You', Colors.blue),
              const SizedBox(width: 10),
              _buildInfoChip(LucideIcons.navigation, '${_distance.toStringAsFixed(1)} km away', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          
          // Problems
          if (problems.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ISSUES REPORTED', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: problems.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Text(p.toString(), style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700)),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 55,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _handleReject,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('REJECT', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF7B61FF)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF00D1FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
