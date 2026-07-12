import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class AppBackground extends StatefulWidget {
  final Widget child;
  /// Set to false for screens whose [Scaffold.bottomNavigationBar] needs to
  /// reach the true screen bottom (e.g. the chat room input bar).
  final bool bottomSafe;
  const AppBackground({super.key, required this.child, this.bottomSafe = true});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _twinkleController;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _twinkleController.dispose();
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
          // Orb 1: Primary Maroon gradient orb (top right / center)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: dark ? 0.25 : 0.16),
                    primaryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(begin: const Offset(-20, -10), end: const Offset(20, 30), duration: 8.seconds, curve: Curves.easeInOutSine),
          ),
          
          // Orb 2: Deep Indigo/Violet gradient orb (bottom left / center)
          Positioned(
            bottom: size.height * 0.1,
            left: -100,
            child: Container(
              width: size.width * 0.95,
              height: size.width * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B1F8F).withValues(alpha: dark ? 0.22 : 0.14),
                    const Color(0xFF3B1F8F).withValues(alpha: 0),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(begin: const Offset(30, 20), end: const Offset(-10, -30), duration: 10.seconds, curve: Curves.easeInOutSine),
          ),

          // Orb 3: Secondary Rose/Pink light orb (middle right)
          Positioned(
            top: size.height * 0.35,
            right: -80,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    secondaryColor.withValues(alpha: dark ? 0.18 : 0.12),
                    secondaryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(begin: const Offset(-10, 20), end: const Offset(-40, -20), duration: 9.seconds, curve: Curves.easeInOutSine),
          ),
          
          // Starry Sky background overlay (only in dark mode)
          if (dark)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _twinkleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: StarrySkyPainter(twinkle: _twinkleController.value),
                  );
                },
              ),
            ),

          // Blur overlay to make it extremely smooth and misty
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Actual content
          SafeArea(bottom: widget.bottomSafe, child: widget.child),
        ],
      ),
    );
  }
}

class StarrySkyPainter extends CustomPainter {
  final double twinkle;
  StarrySkyPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(1337); // constant seed so stars stay in place
    for (int i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.4 + 0.4;
      final baseOpacity = random.nextDouble() * 0.75 + 0.15;
      
      // Vary the phase of twinkle per star using index
      final twinkleVal = (math.sin(twinkle * 2 * math.pi + i) + 1.0) / 2.0;
      paint.color = Colors.white.withValues(alpha: baseOpacity * (0.25 + 0.75 * twinkleVal));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarrySkyPainter oldDelegate) => oldDelegate.twinkle != twinkle;
}
