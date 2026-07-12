import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbController;
  late final AnimationController _pulseController;
  late final AnimationController _twinkleController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    _twinkleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0A020C) : const Color(0xFFFAF5F8),
      body: Stack(
        children: [
          // ── Background Orbs ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) {
              final t = _orbController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -50 + (t * 30),
                    right: -50 + (t * 20),
                    child: Container(
                      width: size.width * 0.85,
                      height: size.width * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: dark ? 0.30 : 0.20),
                            primaryColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.05 - (t * 20),
                    left: -100 + (t * 15),
                    child: Container(
                      width: size.width * 0.95,
                      height: size.width * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF3B1F8F)
                                .withValues(alpha: dark ? 0.28 : 0.18),
                            const Color(0xFF3B1F8F).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.35 + (t * 15),
                    right: -80 - (t * 10),
                    child: Container(
                      width: size.width * 0.65,
                      height: size.width * 0.65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryColor
                                .withValues(alpha: dark ? 0.22 : 0.14),
                            secondaryColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Stars (dark mode only) ───────────────────────────────────────
          if (dark)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _twinkleController,
                builder: (context, _) => CustomPaint(
                  painter: _StarPainter(twinkle: _twinkleController.value),
                ),
              ),
            ),

          // ── Blur overlay ─────────────────────────────────────────────────
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo container
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.04);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          Color(0xFF3B1F8F),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFF3B1F8F).withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.easeOutBack),
                ),

                const SizedBox(height: 28),

                // App name
                Text(
                  'EDUvian',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : primaryColor,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                    begin: 0.2, curve: Curves.easeOut),

                const SizedBox(height: 6),

                // Tagline
                Text(
                  'Your Academic Companion',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dark ? Colors.white54 : Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                const SizedBox(height: 56),

                // Rotating arc loader
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: CustomPaint(
                          painter: _ArcLoaderPainter(dark: dark),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // Loading label
                Text(
                  'Loading...',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: dark ? Colors.white38 : Colors.black38,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARC LOADER PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _ArcLoaderPainter extends CustomPainter {
  final bool dark;
  const _ArcLoaderPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 3;

    // Track (background ring)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Arc sweep
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [primaryColor, Color(0xFF3B1F8F), secondaryColor],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,        // start at top
      math.pi * 1.4,       // sweep ~252°
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcLoaderPainter old) => old.dark != dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR PAINTER  (reused from AppBackground)
// ─────────────────────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  final double twinkle;
  const _StarPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(1337);
    for (int i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.4 + 0.4;
      final base = random.nextDouble() * 0.75 + 0.15;
      final tv = (math.sin(twinkle * 2 * math.pi + i) + 1.0) / 2.0;
      paint.color = Colors.white.withValues(alpha: base * (0.25 + 0.75 * tv));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.twinkle != twinkle;
}
