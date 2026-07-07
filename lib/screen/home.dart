import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/auth_service.dart';
import '../model/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final isLoggedIn = user != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'EDUvian',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Welcome to your\nAcademic Portal",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark(context) ? Colors.white : primaryColor,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                const SizedBox(height: 10),
                Text(
                  "What would you like to calculate today?",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark(context) ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10, bottom: 100), // padding so cards don't hide behind floating notch bar
                    children: [
                      _CalculatorCard(
                        icon: Icons.attach_money_rounded,
                        label: 'Credit & Cost',
                        description: 'Manage semester credits and calculate tuition fees.',
                        color: const Color(0xFFE84545),
                        route: '/credit',
                        delay: 200,
                      ),
                      const SizedBox(height: 24),
                      _CalculatorCard(
                        icon: Icons.school_rounded,
                        label: 'GPA Calculator',
                        description: 'Estimate your semester Grade Point Average.',
                        color: const Color(0xFF4A90E2),
                        route: '/gpa',
                        delay: 350,
                      ),
                      const SizedBox(height: 24),
                      _CalculatorCard(
                        icon: Icons.workspace_premium_rounded,
                        label: 'CGPA Calculator',
                        description: 'Track cumulative academic progress over semesters.',
                        color: const Color(0xFF903749),
                        route: '/cgpa',
                        delay: 500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final String route;
  final int delay;

  const _CalculatorCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.route,
    required this.delay,
  });

  @override
  State<_CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<_CalculatorCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    
    // Custom gradient for each card depending on its route/type
    final Gradient cardGradient;
    final String footerText;
    
    if (widget.route == '/credit') {
      cardGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark 
          ? [const Color(0xFF3E081F), const Color(0xFF7A1431)]
          : [const Color(0xFF5A0D2E), const Color(0xFFE84545).withValues(alpha: 0.85)],
      );
      footerText = 'Tuition Fees & Credits';
    } else if (widget.route == '/gpa') {
      cardGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
          ? [const Color(0xFF13083B), const Color(0xFF323B9B)]
          : [const Color(0xFF221163), const Color(0xFF4A90E2).withValues(alpha: 0.85)],
      );
      footerText = 'Semester Average';
    } else {
      cardGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
          ? [const Color(0xFF3A0826), const Color(0xFF7D1B44)]
          : [const Color(0xFF5C0F39), const Color(0xFF903749).withValues(alpha: 0.85)],
      );
      footerText = 'Cumulative Average';
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {
        context.push(widget.route);
        setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        transform: Matrix4.identity()..scale(_isHovered ? 0.98 : 1.0),
        margin: const EdgeInsets.only(top: 10), // space for overflow icon
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The Glass Card Base
            Container(
              height: 125,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: cardGradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _isHovered ? 0.35 : 0.15),
                    blurRadius: _isHovered ? 24 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15), // subtle tint
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left upper section: Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.55,
                              child: Text(
                                widget.description,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Left lower section: Footer label
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              footerText,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Overlapping 3D floating icon
            Positioned(
              top: -18,
              right: 15,
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: _isHovered ? 24 : 16,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon, 
                  size: 32, 
                  color: Colors.white,
                ),
              ).animate(target: _isHovered ? 1 : 0).scale(end: const Offset(1.1, 1.1)),
            ),
            
            // Faint bottom-right glowing arrow indicator
            Positioned(
              bottom: 15,
              right: 15,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.6),
              ).animate(target: _isHovered ? 1 : 0).move(end: const Offset(6, 0)),
            ),
          ],
        ),
      ),
    );
  }
}
