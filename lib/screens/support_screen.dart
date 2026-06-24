import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixoo_partner/screens/chatbot_screen.dart';
import 'package:fixoo_partner/screens/jini_summoning_screen.dart';
import 'dart:ui';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
        title: const Text('Support Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(bottom: -50, left: -50, child: _glow(const Color(0xFF0FF4C6), 0.03, 250)),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSupportCard(
                'Chat with us',
                'Start a conversation with our FixooIndia AI assistant.',
                LucideIcons.messageCircle,
                const Color(0xFF00D1FF),
                () => Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    pageBuilder: (context, _, __) => const JiniSummoningScreen(),
                    transitionsBuilder: (context, anim, __, child) => FadeTransition(opacity: anim, child: child),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                'Call Support',
                'Directly call our partner helpline for urgent issues.',
                LucideIcons.phone,
                const Color(0xFF0FF4C6),
                () => launchUrl(Uri.parse('tel:+918084886252')),
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                'Email Us',
                'Send us your queries and we\'ll reply within 24 hours.',
                LucideIcons.mail,
                const Color(0xFF7B61FF),
                () => launchUrl(Uri.parse('mailto:support@FixooIndia.com')),
              ),
              const SizedBox(height: 32),
              const Text('Frequently Asked Questions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _buildFaqItem('How to payout my earnings?'),
              _buildFaqItem('I am not receiving new orders.'),
              _buildFaqItem('How to update my document details?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(question, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.2), size: 18),
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
