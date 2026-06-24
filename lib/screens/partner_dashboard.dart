import 'package:flutter/material.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/order_details_screen.dart';
import 'package:fixoo_partner/screens/job_tracking_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';

class PartnerDashboard extends StatefulWidget {
  const PartnerDashboard({super.key});

  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  final _bookingsStream = SupabaseService.getBookingsStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Live Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(LucideIcons.search, color: Colors.white70, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search coming soon!')));
              },
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(top: -100, right: -100, child: _buildGlow(const Color(0xFF00D1FF), 0.04)),
          Positioned(bottom: -100, left: -100, child: _buildGlow(const Color(0xFF0FF4C6), 0.02)),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final bookings = snapshot.data ?? [];
              
              final pendingOrders = bookings.where((b) => 
                b['status'] == 'Pending' && !SupabaseService.acceptedIds.contains(b['id'].toString())
              ).toList();
              
              final myOrders = bookings.where((b) {
                final status = b['status'];
                final isMine = b['partner_id'] == SupabaseService.currentUser?.id;
                final isLocallyAccepted = SupabaseService.acceptedIds.contains(b['id'].toString());
                
                return (isMine && (status == 'Accepted' || status == 'Arrived' || status == 'In Progress' || status == 'Cancelled')) || isLocallyAccepted;
              }).toList();

              if (pendingOrders.isEmpty && myOrders.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  if (myOrders.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                      child: Text('MY ACTIVE JOBS', style: TextStyle(color: Color(0xFF00D1FF), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                    ...myOrders.map((order) => _buildOrderCard(order, isMine: true)).toList(),
                    const SizedBox(height: 20),
                  ],
                  if (pendingOrders.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                      child: Text('NEW REQUESTS', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                    ...pendingOrders.map((order) => _buildOrderCard(order, isMine: false)).toList(),
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double opacity) {
    return Container(
      width: 300, height: 300,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), shape: BoxShape.circle),
            child: const Icon(LucideIcons.radar, size: 60, color: Color(0xFF00D1FF)),
          ),
          const SizedBox(height: 30),
          const Text('Searching for orders...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Stay online to receive new service requests\nin your area.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> booking, {required bool isMine}) {
    final status = booking['status'] ?? 'Pending';
    final isCancelled = status == 'Cancelled';
    final isActuallyMine = isMine || status == 'Arrived' || status == 'In Progress' || isCancelled;
    final problems = List<String>.from(booking['problems'] ?? []);
    final createdAt = DateTime.tryParse(booking['created_at'] ?? '');
    final timeAgo = createdAt != null ? _timeAgo(createdAt) : 'Just now';

    final themeColor = isCancelled ? Colors.redAccent : (isActuallyMine ? const Color(0xFF00D1FF) : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(timeAgo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    if (isActuallyMine)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(status.toUpperCase(), style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(booking['service_name'] ?? 'Service', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(booking['brand'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Color(0xFF00D1FF), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(booking['address'] ?? 'Customer Location', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(LucideIcons.calendarClock, color: Color(0xFF00D1FF), size: 16),
                    const SizedBox(width: 8),
                    Text(booking['scheduled_date'] ?? 'As soon as possible', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ),
                if (problems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: problems.take(2).map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: Text(p, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                    )).toList(),
                  ),
                ]
              ],
            ),
          ),
          if (!isActuallyMine)
            GestureDetector(
              onTap: () => _acceptOrder(booking),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF00D1FF),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: const Center(
                  child: Text('ACCEPT ORDER', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ),
          if (isActuallyMine)
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => JobTrackingScreen(booking: booking)));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                ),
                child: Center(
                  child: Text(status == 'Accepted' ? 'TRACK JOB' : 'RESUME TRACKING', style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(Map<String, dynamic> booking) async {
    final id = booking['id'].toString();
    setState(() => SupabaseService.acceptedIds.add(id)); // Instant move to My Jobs
    try {
      await SupabaseService.acceptBooking(booking['id']);
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Accepted!'), backgroundColor: Colors.green));
        Navigator.push(context, MaterialPageRoute(builder: (_) => JobTrackingScreen(booking: booking)));
      }
    } catch (e) {
      setState(() => SupabaseService.acceptedIds.remove(id)); // Move back on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
