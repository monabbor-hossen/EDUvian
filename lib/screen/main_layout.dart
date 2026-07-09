import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_service.dart';
import '../model/routine.dart';
import '../model/widgets.dart';

// UIDs for which we've already run the academic-info check this app session.
// Public so login.dart / signup.dart can clear entries for brand-new users.
final Set<String> checkedUids = {};

class MainLayoutScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  // Prevents scheduling the dialog more than once per widget instance.
  bool _dialogPending = false;

  /// Schedules the academic-info dialog to show after the current frame.
  /// Safe to call from build() because it only uses postFrameCallback.
  void _scheduleDialogIfNeeded(String uid) {
    if (_dialogPending) return;          // already scheduled this instance
    if (checkedUids.contains(uid)) return; // already shown this session
    _dialogPending = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Mark as checked BEFORE showing so re-entrancy is impossible.
      checkedUids.add(uid);

      final prefs = await SharedPreferences.getInstance();
      final info = prefs.getString('academic_info') ?? '';
      if (info.isEmpty && mounted) {
        await showAcademicInfoSetupDialog(context);
        if (mounted) ref.invalidate(academicInfoProvider);
      }
    });
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);

    // ref.watch fires on EVERY build — including the very first one and
    // whenever auth state resolves. This is the reliable trigger point.
    final authAsync = ref.watch(authStateProvider);
    authAsync.whenData((user) {
      if (user != null) _scheduleDialogIfNeeded(user.uid);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, // This allows the body to flow behind the floating nav bar
      body: AppBackground(child: widget.navigationShell),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // The curved bottom bar container
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
              child: ClipPath(
                clipper: CurvedBottomBarClipper(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: CustomPaint(
                    painter: CurvedBottomBarPainter(
                      color: dark ? Colors.black.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.55),
                      borderColor: dark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Container(
                      height: 75,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left items: Home + Routine
                          Row(
                            children: [
                              _buildNavItem(Icons.space_dashboard_rounded, 'Home', 0, dark),
                              _buildNavItem(Icons.calendar_month_rounded, 'Routine', 1, dark),
                            ],
                          ),

                          // Spacer for center FAB notch
                          const SizedBox(width: 80),

                          // Right items: Calculator + Settings
                          Row(
                            children: [
                              _buildNavItem(Icons.calculate_rounded, 'Calc', 3, dark),
                              _buildNavItem(Icons.settings_rounded, 'Settings', 4, dark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Center FAB: Messages (index 2)
            Positioned(
              bottom: 45,
              child: _buildCenterButton(Icons.forum_rounded, 2, dark),
            ),
          ],
        ),
      ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool dark) {
    final isSelected = widget.navigationShell.currentIndex == index;
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(index),
      child: Container(
        width: 56,
        height: 60,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                ? primaryColor 
                : (dark ? Colors.white54 : Colors.black45),
            ).animate(target: isSelected ? 1 : 0)
             .scale(end: const Offset(1.15, 1.15))
             .tint(color: primaryColor, end: isSelected ? 1.0 : 0.0),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? primaryColor : (dark ? Colors.white54 : Colors.black45),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(IconData icon, int index, bool dark) {
    final isSelected = widget.navigationShell.currentIndex == index;
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);
    
    return GestureDetector(
      onTap: () => _onTap(index),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEC4899), // vibrant pink
              primaryColor,      // deep maroon
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 30,
          color: Colors.white,
        ),
      )
      .animate(target: isSelected ? 1 : 0)
      .scale(end: const Offset(1.15, 1.15))
      .shimmer(delay: 500.ms, duration: 1200.ms, color: Colors.white24),
    );
  }
}

class CurvedBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 25)
      ..quadraticBezierTo(0, 0, 25, 0)
      ..lineTo(size.width / 2 - 50, 0)
      ..cubicTo(
        size.width / 2 - 32, 0,
        size.width / 2 - 35, 34,
        size.width / 2, 34,
      )
      ..cubicTo(
        size.width / 2 + 35, 34,
        size.width / 2 + 32, 0,
        size.width / 2 + 50, 0,
      )
      ..lineTo(size.width - 25, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CurvedBottomBarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  CurvedBottomBarPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 25)
      ..quadraticBezierTo(0, 0, 25, 0)
      ..lineTo(size.width / 2 - 50, 0)
      ..cubicTo(
        size.width / 2 - 32, 0,
        size.width / 2 - 35, 34,
        size.width / 2, 34,
      )
      ..cubicTo(
        size.width / 2 + 35, 34,
        size.width / 2 + 32, 0,
        size.width / 2 + 50, 0,
      )
      ..lineTo(size.width - 25, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    
    // Paint only the top glowing border
    final borderPath = Path()
      ..moveTo(0, 25)
      ..quadraticBezierTo(0, 0, 25, 0)
      ..lineTo(size.width / 2 - 50, 0)
      ..cubicTo(
        size.width / 2 - 32, 0,
        size.width / 2 - 35, 34,
        size.width / 2, 34,
      )
      ..cubicTo(
        size.width / 2 + 35, 34,
        size.width / 2 + 32, 0,
        size.width / 2 + 50, 0,
      )
      ..lineTo(size.width - 25, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 25);
      
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
