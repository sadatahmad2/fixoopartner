import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/history_screen.dart';
import 'package:fixoo_partner/screens/support_screen.dart';
import 'package:fixoo_partner/screens/notifications_screen.dart';
import 'package:fixoo_partner/screens/documents_screen.dart';
import 'package:fixoo_partner/screens/earnings_screen.dart';
import 'package:fixoo_partner/screens/chatbot_screen.dart';
import 'package:fixoo_partner/screens/jini_summoning_screen.dart';
import 'package:fixoo_partner/screens/job_tracking_screen.dart';
import 'package:fixoo_partner/providers/partner_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  bool _isOnline = true;
  bool _isLoading = true;
  late AnimationController _pulseCtrl;
  late AnimationController _entryCtrl;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _activities = [];
  Offset _botPosition = const Offset(0, 0); // Initialized in didChangeDependencies

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_botPosition == const Offset(0, 0)) {
      final size = MediaQuery.of(context).size;
      _botPosition = Offset(size.width - 80, size.height - 180);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProfile(),
      _fetchStats(),
      _fetchRecentActivity(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await SupabaseService.getProfile();
      if (mounted) {
        setState(() {
          _profile = data;
        });
        // Sync with provider
        Provider.of<PartnerProvider>(context, listen: false).fetchStatus();
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchStats() async {
    try {
      final data = await SupabaseService.getPartnerStats();
      if (mounted) setState(() => _stats = data);
    } catch (e) {}
  }

  Future<void> _fetchRecentActivity() async {
    try {
      final data = await SupabaseService.getRecentActivity();
      if (mounted) setState(() => _activities = data);
    } catch (e) {}
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _glow(const Color(0xFF00D1FF), 0.04, 350)),
          Positioned(bottom: -100, left: -60, child: _glow(const Color(0xFF0FF4C6), 0.025, 300)),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFF00D1FF),
              backgroundColor: const Color(0xFF030712),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (context, _) {
                  final fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut).value;
                  return Opacity(
                    opacity: fade,
                    child: Transform.translate(
                      offset: Offset(0, (1 - fade) * 30),
                      child: _buildContent(),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Draggable Jini Bot
          Positioned(
            left: _botPosition.dx,
            top: _botPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _botPosition += details.delta;
                });
              },
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, _, __) => const JiniSummoningScreen(),
                    transitionsBuilder: (context, anim, __, child) => FadeTransition(opacity: anim, child: child),
                  ),
                );
              },
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF030712).withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00D1FF).withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/images/genie_icon.png', width: 44, height: 44, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 16),
        _buildHeader(),
        const SizedBox(height: 28),
        _buildOnlineToggle(),
        const SizedBox(height: 28),
        _buildIncomingOrders(),
        const SizedBox(height: 28),
        _buildStatsRow(),
        const SizedBox(height: 28),
        _buildTodaySummaryCard(),
        const SizedBox(height: 28),
        _buildQuickActions(),
        const SizedBox(height: 28),
        _buildRecentActivity(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _profile?['avatar_url'] == null 
                ? const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF0FF4C6)])
                : null,
            image: _profile?['avatar_url'] != null 
                ? DecorationImage(image: NetworkImage(_profile!['avatar_url']), fit: BoxFit.cover)
                : null,
            boxShadow: [BoxShadow(color: const Color(0xFF00D1FF).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
            child: _profile?['avatar_url'] == null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  )
                : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good ${_getGreeting()} 👋', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(_profile?['name'] ?? 'FixooIndia Partner', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Stack(
              children: [
                Center(child: Icon(LucideIcons.bell, color: Colors.white.withOpacity(0.6), size: 20)),
                Positioned(top: 10, right: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00D1FF), shape: BoxShape.circle))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineToggle() {
    final partnerProvider = Provider.of<PartnerProvider>(context);
    final isOnline = partnerProvider.isOnline;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final pulse = isOnline ? (0.6 + _pulseCtrl.value * 0.4) : 0.0;
        return GestureDetector(
          onTap: () async {
            final newStatus = !isOnline;
            await partnerProvider.updateStatus(newStatus);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isOnline
                    ? [const Color(0xFF00D1FF).withOpacity(0.12), const Color(0xFF0FF4C6).withOpacity(0.06)]
                    : [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.02)],
              ),
              border: Border.all(
                color: isOnline ? const Color(0xFF00D1FF).withOpacity(0.25) : Colors.white.withOpacity(0.06),
              ),
              boxShadow: isOnline
                  ? [BoxShadow(color: const Color(0xFF00D1FF).withOpacity(pulse * 0.08), blurRadius: 40, spreadRadius: 5)]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? const Color(0xFF00D1FF).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    boxShadow: isOnline ? [BoxShadow(color: const Color(0xFF00D1FF).withOpacity(pulse * 0.4), blurRadius: 20)] : [],
                  ),
                  child: Icon(isOnline ? LucideIcons.wifi : LucideIcons.wifiOff, color: isOnline ? const Color(0xFF00D1FF) : Colors.white38, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? "You're Online" : "You're Offline",
                        style: TextStyle(color: isOnline ? Colors.white : Colors.white54, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isOnline ? 'Receiving new order requests' : 'Tap to go online & receive orders',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Toggle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: 56, height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isOnline ? const Color(0xFF00D1FF) : Colors.white.withOpacity(0.1),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24, height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? Colors.black : Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingOrders() {
    final partnerProvider = Provider.of<PartnerProvider>(context);
    if (!partnerProvider.isOnline) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getBookingsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final List<String> skills = partnerProvider.skills;
        final isBusy = _stats?['active_job'] == true; // Simple check

        final newOrders = snapshot.data!.where((b) {
          if (b['status'] != 'Pending') return false;
          if (SupabaseService.acceptedIds.contains(b['id'].toString())) return false;

          // Check if request is older than 30 minutes (Expired)
          if (b['created_at'] != null) {
            final createdAt = DateTime.parse(b['created_at']);
            final now = DateTime.now();
            if (now.difference(createdAt).inMinutes > 30) {
              return false; // Hide expired requests
            }
          }

          // Check eligibility
          double dist = 0;
          if (partnerProvider.profile?['latitude'] != null && b['latitude'] != null) {
            dist = SupabaseService.calculateDistance(
              partnerProvider.profile!['latitude'], partnerProvider.profile!['longitude'],
              b['latitude'] as double, b['longitude'] as double
            ) / 1000;
          }

          return SupabaseService.isEligibleForBooking(
            booking: b,
            technicianSkills: skills,
            distanceInKm: dist,
            isCurrentlyBusy: isBusy,
          );
        }).toList();
        if (newOrders.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Incoming Requests', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...newOrders.map((order) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF081020)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF0FF4C6).withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF0FF4C6).withOpacity(0.1), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['service_name'] ?? 'Service Request', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('₹${order['price'] ?? 0}', style: const TextStyle(color: Color(0xFF0FF4C6), fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${order['brand'] ?? 'Unknown Brand'} • ${order['problems']?.join(', ') ?? 'General Issue'}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, color: Colors.white.withOpacity(0.4), size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(order['address'] ?? 'Customer Location', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final id = order['id'];
                            setState(() => SupabaseService.acceptedIds.add(id.toString())); // Global hide
                            try {
                              await SupabaseService.rejectBooking(id);
                            } catch (e) {
                              setState(() => SupabaseService.acceptedIds.remove(id.toString())); // Global show again on error
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                            child: const Center(child: Text('REJECT', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w800))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final id = order['id'];
                            setState(() => SupabaseService.acceptedIds.add(id.toString())); // Global hide
                            try {
                              await SupabaseService.acceptBooking(id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted! Go to Orders tab to track.')));
                              }
                            } catch (e) {
                              setState(() => SupabaseService.acceptedIds.remove(id.toString())); // Global show on error
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF0FF4C6)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(child: Text('ACCEPT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen())),
            child: _buildStatCard('Today\'s Jobs', _stats?['today_jobs'] ?? '0', LucideIcons.briefcase, const Color(0xFF00D1FF)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Completed', _stats?['completed'] ?? '0', LucideIcons.circleCheck, const Color(0xFF0FF4C6))),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rating', _stats?['rating'] ?? '0.0', LucideIcons.star, const Color(0xFFFFD700))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    final earnings = _stats?['earnings_today'] ?? '0';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Earnings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text('₹$earnings', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 6),
          Text('${_stats?['today_jobs'] ?? '0'} services today', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildActionTile('Service History', LucideIcons.history, const Color(0xFF00D1FF), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile('Support', LucideIcons.headphones, const Color(0xFF0FF4C6), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile('Documents', LucideIcons.fileText, const Color(0xFF7B61FF), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildActionTile('Training', LucideIcons.graduationCap, const Color(0xFFFFD700), () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner Training coming soon!')));
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            if (_activities.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                child: Text('View All', style: TextStyle(color: const Color(0xFF00D1FF).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_activities.isEmpty && !_isLoading)
           Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 40),
               child: Column(
                 children: [
                   Icon(LucideIcons.layers, color: Colors.white10, size: 48),
                   const SizedBox(height: 12),
                   Text('No recent activity', style: TextStyle(color: Colors.white24, fontSize: 14)),
                 ],
               ),
             ),
           )
        else
          ..._activities.map((act) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildActivityItem(
              act['title'] ?? 'Service',
              act['status'] ?? 'Unknown',
              act['amount'] ?? '₹0',
              act['time'] ?? 'Recently',
              act['status'] == 'Completed' ? LucideIcons.circleCheck : LucideIcons.clock,
              act['status'] == 'Completed' ? const Color(0xFF0FF4C6) : const Color(0xFFFFD700),
              () {},
            ),
          )),
      ],
    );
  }

  Widget _buildActivityItem(String title, String status, String amount, String time, IconData icon, Color statusColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Details for $title coming soon!'))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
