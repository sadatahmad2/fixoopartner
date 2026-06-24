import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fixoo_partner/screens/otp_screen.dart';
import 'package:fixoo_partner/screens/home_screen.dart';
import 'package:fixoo_partner/screens/complete_profile_screen.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'dart:ui';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  late AnimationController _animCtrl;
  bool _isLoading = false;

  static const _bg = Color(0xFF040C18);
  static const _cyan = Color(0xFF00D1FF);
  static const _accent = Color(0xFF0FF4C6);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 10-digit number'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final fullPhone = '+91$phone';
    try {
      await SupabaseService.sendOTP(fullPhone);
    } catch (e) {
      // Continue to OTP screen even if sendOTP fails (mock mode etc.)
    }
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => OTPScreen(phoneNumber: fullPhone)));
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.signInWithGoogle();
      if (response != null && response.user != null && mounted) {
        final isComplete = await SupabaseService.isProfileComplete();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => isComplete ? const HomeScreen() : const CompleteProfileScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Soft ambient glows
          Positioned(top: -120, right: -80, child: _glow(_cyan, 0.04, 350)),
          Positioned(bottom: -100, left: -60, child: _glow(_accent, 0.025, 300)),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 60),

                          // Logo + Brand
                          _buildItem(0.0, Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _cyan.withValues(alpha: 0.2), width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (b) => const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFFF2B0), Colors.white],
                                      ).createShader(b),
                                      child: const Text('FixooIndia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Partner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: _cyan, letterSpacing: 1)),
                                  ],
                                ),
                              ],
                            ),
                          )),

                          const SizedBox(height: 50),

                          // Welcome text
                          _buildItem(0.15, Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome,\nService Partner',
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sign in to manage your bookings & earnings',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, fontWeight: FontWeight.w400),
                              ),
                            ],
                          )),

                          const SizedBox(height: 40),

                          // Phone input
                          _buildItem(0.3, Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 20, right: 15),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('+91', style: TextStyle(color: _cyan, fontSize: 17, fontWeight: FontWeight.w900)),
                                      const SizedBox(width: 12),
                                      Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.08)),
                                    ],
                                  ),
                                ),
                                hintText: 'Mobile Number',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 22),
                              ),
                            ),
                          )),

                          const SizedBox(height: 20),

                          // Login button
                          _buildItem(0.45, SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cyan,
                                foregroundColor: const Color(0xFF040C18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              child: _isLoading && _phoneController.text.isNotEmpty
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF040C18)))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.arrowRight, size: 18),
                                      ],
                                    ),
                            ),
                          )),

                          const SizedBox(height: 24),

                          // Divider
                          _buildItem(0.5, Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.08))),
                            ],
                          )),

                          const SizedBox(height: 24),

                          // Google Login
                          _buildItem(0.55, SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: Colors.white.withValues(alpha: 0.02),
                              ),
                              child: _isLoading && _phoneController.text.isEmpty
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Sign in with Google', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                            ),
                          )),

                          const SizedBox(height: 28),

                          // Info cards
                          _buildItem(0.6, Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              children: [
                                _infoRow(LucideIcons.briefcase, 'Get jobs directly from customers'),
                                const SizedBox(height: 14),
                                _infoRow(LucideIcons.wallet, 'Track your earnings in real-time'),
                                const SizedBox(height: 14),
                                _infoRow(LucideIcons.shield, 'Verified & secure platform'),
                              ],
                            ),
                          )),

                          const Spacer(),

                          // Terms
                          _buildItem(0.7, Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'By continuing, you agree to FixooIndia\'s Terms of Service',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _cyan, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildItem(double delay, Widget child) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        final progress = ((_animCtrl.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: child,
          ),
        );
      },
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
