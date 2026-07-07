import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../model/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, 'Dashboard'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: GlassContainer(
              padding: const EdgeInsets.all(40),
              blur: 30,
              alpha: 0.6,
              borderRadius: BorderRadius.circular(32),
              borderColor: dark ? Colors.white12 : Colors.white60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 64,
                      color: primaryColor,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds)
                   .shimmer(color: Colors.white54, duration: 2.seconds),
                  const SizedBox(height: 32),
                  Text(
                    'Your Academic\nJourney',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  Text(
                    'Exciting new features and analytics are coming to this space soon.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: dark ? Colors.white60 : Colors.black54,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
