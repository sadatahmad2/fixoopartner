import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:fixoo_partner/screens/chatbot_screen.dart';

class JiniSummoningScreen extends StatefulWidget {
  const JiniSummoningScreen({super.key});

  @override
  State<JiniSummoningScreen> createState() => _JiniSummoningScreenState();
}

class _JiniSummoningScreenState extends State<JiniSummoningScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _irisAnimation;
  late Animation<double> _jiniPosition;
  late Animation<double> _jiniOpacity;
  late Animation<double> _smokeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500));

    // Phase 1: Shutter/Iris closing (0.0 to 0.3)
    _irisAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.3, curve: Curves.easeInOut)),
    );

    // Phase 2: Smoke rising (0.2 to 0.9)
    _smokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOut)),
    );

    // Phase 3: Jini rising from bottom with smoke (0.4 to 0.8)
    _jiniPosition = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );
    _jiniOpacity = Tween<double>(begin: 0.0, end: 0.85).animate( // Slightly transparent
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _ctrl.forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, _, __) => const ChatBotScreen(),
                transitionsBuilder: (context, anim, __, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            children: [
              // 1. Black Iris Overlay
              CustomPaint(
                painter: IrisPainter(_irisAnimation.value),
                size: Size.infinite,
              ),
              
              // 2. Smoke Particles rising
              if (_ctrl.value > 0.2)
                Positioned.fill(
                  child: CustomPaint(
                    painter: SmokePainter(_smokeAnimation.value),
                  ),
                ),

              // 3. Jini Rising & Transparent
              if (_ctrl.value > 0.4)
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _jiniPosition.value),
                    child: Opacity(
                      opacity: _jiniOpacity.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Spirit glow
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D1FF).withValues(alpha: 0.4 * _jiniOpacity.value),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/genie_icon.png', 
                              width: 250, height: 250,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "JINI IS MANIFESTING...",
                            style: TextStyle(
                              color: const Color(0xFF00D1FF).withValues(alpha: _jiniOpacity.value),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(color: const Color(0xFF00D1FF), blurRadius: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class IrisPainter extends CustomPainter {
  final double progress;
  IrisPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 1.5;
    final currentHoleRadius = maxRadius * (1.0 - progress);
    
    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: currentHoleRadius.clamp(0, maxRadius)))
      ..fillType = PathFillType.evenOdd;
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(IrisPainter oldDelegate) => oldDelegate.progress != progress;
}

class SmokePainter extends CustomPainter {
  final double progress;
  final List<SmokeParticle> particles;

  SmokePainter(this.progress) : particles = List.generate(25, (i) => SmokeParticle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final pProgress = (progress + particle.delay).clamp(0.0, 1.0);
      if (pProgress <= 0) continue;

      final x = size.width / 2 + particle.xOffset * math.sin(pProgress * 10);
      final y = size.height * (0.8 - pProgress * 0.7);
      final radius = particle.baseSize * (1.0 + pProgress * 2);
      final opacity = (1.0 - pProgress) * 0.3;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00D1FF).withValues(alpha: opacity),
            const Color(0xFF7B61FF).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(SmokePainter oldDelegate) => oldDelegate.progress != progress;
}

class SmokeParticle {
  final double xOffset;
  final double delay;
  final double baseSize;

  SmokeParticle(int index)
      : xOffset = (index % 5 - 2) * 40.0 + (math.Random().nextDouble() * 20),
        delay = (index / 25.0) * -0.5,
        baseSize = 20.0 + math.Random().nextDouble() * 30.0;
}
