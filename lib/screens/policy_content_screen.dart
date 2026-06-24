import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';

class PolicyContentScreen extends StatelessWidget {
  final String title;
  const PolicyContentScreen({super.key, required this.title});

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
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _glow(const Color(0xFF00D1FF), 0.03, 250)),
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSection('1. Introduction', 'Welcome to FixooIndia. These $title outline the rules and regulations for the use of FixooIndia\'s Partner Application.'),
              _buildSection('2. Acceptance of Terms', 'By accessing this app, we assume you accept these terms and conditions. Do not continue to use FixooIndia Partner if you do not agree to all of the terms and conditions stated on this page.'),
              _buildSection('3. Partner Responsibilities', 'As a service provider on our platform, you agree to provide services with the highest quality and professionalism. You are responsible for maintaining the accuracy of your profile and documentation.'),
              _buildSection('4. Payments & Commissions', 'Payments are processed after successful completion of jobs. FixooIndia reserves the right to deduct a service commission as agreed upon during registration.'),
              _buildSection('5. Data Privacy', 'Your data is safe with us. We use your personal and professional information only for verification and job matching purposes as described in our Privacy Policy.'),
              _buildSection('6. Termination', 'We may terminate or suspend access to our service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.'),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  '© 2026 FixooIndia Technologies Pvt. Ltd.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String heading, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: const TextStyle(color: Color(0xFF00D1FF), fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 32),
      ],
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
