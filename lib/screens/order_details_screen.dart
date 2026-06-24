import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/job_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const OrderDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final problems = List<String>.from(booking['problems'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Job Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _glow(const Color(0xFF00D1FF), 0.03, 300)),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 24),
              _buildInfoSection('Service Information', [
                _buildInfoRow(LucideIcons.briefcase, 'Service', booking['service_name'] ?? 'N/A'),
                _buildInfoRow(LucideIcons.tag, 'Brand', booking['brand'] ?? 'N/A'),
                _buildInfoRow(LucideIcons.calendar, 'Scheduled', booking['scheduled_date'] ?? 'N/A'),
              ]),
              const SizedBox(height: 20),
              _buildInfoSection('Customer Location', [
                _buildInfoRow(LucideIcons.mapPin, 'Address', booking['address'] ?? 'Customer Location'),
              ]),
              const SizedBox(height: 20),
              if (problems.isNotEmpty) ...[
                const Text('Reported Problems', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: problems.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                    child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  )).toList(),
                ),
                const SizedBox(height: 30),
              ],
              if (booking['status'] == 'Pending')
                _buildActionButton('ACCEPT JOB', const Color(0xFF00D1FF), Colors.black, () => _handleAccept(context))
              else ...[
                _buildActionButton('NAVIGATE TO LOCATION', const Color(0xFF00D1FF), Colors.black, () {
                  _launchNavigation(booking['address']);
                }),
                const SizedBox(height: 12),
                _buildActionButton(
                  'TRACK JOB PROGRESS', 
                  const Color(0xFF0FF4C6).withValues(alpha: 0.1), 
                  const Color(0xFF0FF4C6),
                  () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => JobTrackingScreen(booking: booking)));
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _launchNavigation(String? address) async {
    if (address == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _handleAccept(BuildContext context) async {
    try {
      await SupabaseService.acceptBooking(booking['id'].toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted!'), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => JobTrackingScreen(booking: booking)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _handleComplete(BuildContext context) async {
    try {
      await SupabaseService.completeBooking(booking['id'].toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Completed Successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleCheck, color: Color(0xFF0FF4C6), size: 24),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('You have accepted this job', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D1FF), size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bg, Color text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Text(label, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
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
