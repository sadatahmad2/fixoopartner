import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/screens/policy_content_screen.dart';
import 'dart:ui';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: const Text('Terms & Policies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: _glow(const Color(0xFF00D1FF), 0.03, 250)),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildPolicyItem(context, 'Privacy Policy', 'Last updated: Jan 15, 2026'),
              _buildPolicyItem(context, 'Terms of Service', 'Last updated: Jan 10, 2026'),
              _buildPolicyItem(context, 'Partner Code of Conduct', 'Last updated: Dec 20, 2025'),
              _buildPolicyItem(context, 'Cancellation Policy', 'Last updated: Jan 05, 2026'),
              _buildPolicyItem(context, 'Cookie Policy', 'Last updated: Nov 12, 2025'),
              
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'By using this app, you agree to our policies.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String title, String update) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyContentScreen(title: title)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFF00D1FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(LucideIcons.fileText, color: Color(0xFF00D1FF), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(update, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.white.withValues(alpha: 0.2), size: 18),
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
