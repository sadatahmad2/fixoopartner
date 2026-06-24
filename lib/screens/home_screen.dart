import 'package:flutter/material.dart';
import 'package:fixoo_partner/screens/partner_dashboard.dart';
import 'package:fixoo_partner/screens/earnings_screen.dart';
import 'package:fixoo_partner/screens/profile_screen.dart';
import 'package:fixoo_partner/screens/home_tab.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/widgets/booking_request_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:fixoo_partner/providers/notification_provider.dart';
import 'package:fixoo_partner/providers/partner_provider.dart';
import 'package:fixoo_partner/screens/job_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabPulseCtrl;
  Map<String, dynamic>? _profile;
  StreamSubscription? _bookingSubscription;
  final Set<String> _notifiedBookings = {};
  Position? _currentPosition;

  final List<Widget> _screens = const [
    HomeTab(),
    PartnerDashboard(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fetchProfile();
    _startBookingListener();
    _updatePosition();
  }

  Future<void> _updatePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (e) {
      print('DEBUG: Position error: $e');
    }
  }

  void _startBookingListener() {
    _bookingSubscription?.cancel();
    _bookingSubscription = SupabaseService.getBookingsStream().listen((bookings) async {
      if (bookings.isEmpty) return;
      
      // 1. Check if partner is online
      final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
      if (!partnerProvider.isOnline) return;

      // 2. Check if partner is busy
      final isBusy = await SupabaseService.isTechnicianBusy();
      if (isBusy) return;
      
      final pending = bookings.where((b) => b['status'] == 'Pending').toList();
      if (pending.isNotEmpty) {
        final latest = pending.first;
        final id = latest['id'].toString();
        
        if (!_notifiedBookings.contains(id)) {
          // 3. Verify Eligibility (Skills, Smart Radius, etc.)
          final List<String> skills = List<String>.from(_profile?['skills'] ?? []);
          double dist = 0;
          if (_currentPosition != null && latest['latitude'] != null) {
            dist = SupabaseService.calculateDistance(
              _currentPosition!.latitude, _currentPosition!.longitude,
              latest['latitude'] as double, latest['longitude'] as double
            ) / 1000;
          }

          final isEligible = SupabaseService.isEligibleForBooking(
            booking: latest,
            technicianSkills: skills,
            distanceInKm: dist,
            isCurrentlyBusy: isBusy
          );

          if (!isEligible) return;

          // 4. Distance Priority (15s delay if > 3km)
          if (dist > 3.0) {
            await Future.delayed(const Duration(seconds: 15));
            // Re-check status after delay (maybe someone else accepted it)
            final freshBookings = await SupabaseService.getBookings();
            final stillPending = freshBookings.any((b) => b['id'].toString() == id && b['status'] == 'Pending');
            if (!stillPending) return;
          }

          _notifiedBookings.add(id);
          if (mounted) _showBookingPopup(latest);
        }
      }
    });
  }

  void _showBookingPopup(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => BookingRequestPopup(
        booking: booking,
        partnerLat: _currentPosition?.latitude,
        partnerLng: _currentPosition?.longitude,
        onAccept: () {
          SupabaseService.acceptedIds.add(booking['id'].toString()); // Add to global set
          Navigator.pop(context); // Close popup
          setState(() => _currentIndex = 1); // Switch to Orders Tab
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking Accepted! View it in your Orders.'), backgroundColor: Colors.green),
          );
        },
        onReject: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _fetchProfile() async {
    await Provider.of<PartnerProvider>(context, listen: false).fetchStatus();
    final data = await SupabaseService.getProfile();
    if (mounted) setState(() => _profile = data);
  }

  @override
  void dispose() {
    _fabPulseCtrl.dispose();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1C),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, LucideIcons.layoutDashboard, 'Home'),
              _buildNavItem(1, LucideIcons.clipboardList, 'Orders'),
              _buildNavItem(2, LucideIcons.indianRupee, 'Earnings'),
              _buildNavItem(3, LucideIcons.circleUserRound, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isProfile = index == 3;
    final avatarUrl = _profile?['avatar_url'];

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D1FF).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProfile && avatarUrl != null)
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
                  border: Border.all(color: isSelected ? const Color(0xFF00D1FF) : Colors.transparent, width: 1.5),
                ),
              )
            else
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF00D1FF)
                    : Colors.white.withValues(alpha: 0.35),
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF00D1FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
