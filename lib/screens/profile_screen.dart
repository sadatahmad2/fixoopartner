import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/auth_screen.dart';
import 'package:fixoo_partner/screens/support_screen.dart';
import 'package:fixoo_partner/screens/edit_profile_screen.dart';
import 'package:fixoo_partner/screens/documents_screen.dart';
import 'package:fixoo_partner/screens/bank_details_screen.dart';
import 'package:fixoo_partner/screens/earnings_screen.dart';
import 'package:fixoo_partner/screens/history_screen.dart';
import 'package:fixoo_partner/screens/notifications_screen.dart';
import 'package:fixoo_partner/screens/settings_screen.dart';
import 'package:fixoo_partner/screens/terms_screen.dart';
import 'package:fixoo_partner/screens/edit_skills_screen.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await SupabaseService.getProfile();
      if (mounted) {
        setState(() {
          _profile = data;
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: _glow(const Color(0xFF7B61FF), 0.035, 300)),
          Positioned(bottom: -100, left: -60, child: _glow(const Color(0xFF00D1FF), 0.025, 280)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    TextButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...')));
                        await SupabaseService.getProfile(); // This will trigger _ensureProfileAndWallet
                        _fetchProfile();
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF00D1FF)),
                      label: const Text('Sync with Google', style: TextStyle(color: Color(0xFF00D1FF), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildProfileHeader(),
                const SizedBox(height: 28),
                _buildStatsBar(),
                const SizedBox(height: 28),
                _buildMenuSection('Account', [
                  _MenuItem(LucideIcons.user, 'Personal Details', const Color(0xFF00D1FF)),
                  _MenuItem(LucideIcons.shield, 'Verification', const Color(0xFF0FF4C6)),
                  _MenuItem(LucideIcons.wrench, 'My Skills', const Color(0xFF00D1FF)),
                  _MenuItem(LucideIcons.banknote, 'Bank Details', const Color(0xFF7B61FF)),
                  _MenuItem(LucideIcons.wallet, 'Earnings', const Color(0xFF0FF4C6)),
                  _MenuItem(LucideIcons.history, 'Job History', const Color(0xFF00D1FF)),
                ]),
                const SizedBox(height: 20),
                _buildMenuSection('Preferences', [
                  _MenuItem(LucideIcons.bell, 'Notifications', const Color(0xFFFFD700)),
                  _MenuItem(LucideIcons.settings, 'Settings', const Color(0xFF00D1FF)),
                ]),
                const SizedBox(height: 20),
                _buildMenuSection('Support', [
                  _MenuItem(LucideIcons.headphones, 'Help Center', const Color(0xFF0FF4C6)),
                  _MenuItem(LucideIcons.fileText, 'Terms & Policies', const Color(0xFF00D1FF)),
                ]),
                const SizedBox(height: 28),
                _buildLogoutButton(context),
                const SizedBox(height: 16),
                Center(child: Text('FixooIndia Partner v1.0.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12))),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _profile?['avatar_url'] == null 
                  ? const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF7B61FF)])
                  : null,
              image: _profile?['avatar_url'] != null 
                  ? DecorationImage(image: NetworkImage(_profile!['avatar_url']), fit: BoxFit.cover)
                  : null,
              boxShadow: [BoxShadow(color: const Color(0xFF00D1FF).withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: _profile?['avatar_url'] == null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                  )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_profile?['name'] ?? 'FixooIndia Partner', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                if (_profile?['email'] != null) ...[
                  Text(_profile!['email'], style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  const SizedBox(height: 2),
                ],
                Text(_profile?['phone'] ?? '+91 00000 00000', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0FF4C6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.badgeCheck, color: Color(0xFF0FF4C6), size: 14),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(color: Color(0xFF0FF4C6), fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile)));
              if (updated == true) _fetchProfile();
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(LucideIcons.pencil, color: Colors.white.withValues(alpha: 0.4), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Row(
      children: [
        _buildProfileStat('Jobs Done', '127'),
        const SizedBox(width: 12),
        _buildProfileStat('Rating', '4.8 ★'),
        const SizedBox(width: 12),
        _buildProfileStat('Member Since', 'Jan 2026'),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                       if (item.label == 'Help Center') {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                      } else if (item.label == 'Personal Details') {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: _profile)));
                        if (updated == true) _fetchProfile();
                      } else if (item.label == 'Verification') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                      } else if (item.label == 'My Skills') {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditSkillsScreen(initialSkills: List<String>.from(_profile?['skills'] ?? []))));
                        if (updated == true) _fetchProfile();
                      } else if (item.label == 'Bank Details') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDetailsScreen()));
                      } else if (item.label == 'Earnings') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
                      } else if (item.label == 'Job History') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                      } else if (item.label == 'Notifications') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      } else if (item.label == 'Settings') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      } else if (item.label == 'Terms & Policies') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.label} coming soon!')));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(item.icon, color: item.color, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                          Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.2), size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.white.withValues(alpha: 0.04), indent: 70),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: const Text('Are you sure you want to log out from FixooIndia Partner?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await SupabaseService.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
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

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);
}
