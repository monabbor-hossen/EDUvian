import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/academic_info_setup_dialog.dart';
import '../../../../core/providers/layout_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../routine/presentation/providers/routine_providers.dart';

final Set<String> checkedUids = {};

class MainLayoutScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  bool _dialogPending = false;

  void _scheduleDialogIfNeeded(String uid) {
    if (_dialogPending) return;
    if (checkedUids.contains(uid)) return;
    _dialogPending = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      checkedUids.add(uid);

      final prefs = await SharedPreferences.getInstance();
      var info = prefs.getString('academic_info') ?? '';

      // If not found locally, check Firestore (handles reinstalls / new devices)
      if (info.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final cloudInfo = doc.data()?['academic_info'] as String? ?? '';
          if (cloudInfo.isNotEmpty) {
            // Restore to local cache so future launches skip the cloud call
            await prefs.setString('academic_info', cloudInfo);
            info = cloudInfo;
            if (mounted) {
              ref.invalidate(academicInfoProvider);
            }
          }
        } catch (_) {
          // Network error — fall through and show the dialog
        }
      }

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

    final authAsync = ref.watch(authStateProvider);
    authAsync.whenData((user) {
      if (user != null) {
        _scheduleDialogIfNeeded(user.uid);
      } else {
        // Reset state on logout so it triggers again on next login
        _dialogPending = false;
        checkedUids.clear();
      }
    });

    final navVisible = ref.watch(navBarVisibleProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(child: widget.navigationShell),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        child: navVisible
            ? AnimatedSlide(
                offset: Offset.zero,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                child: AnimatedOpacity(
                  opacity: navVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: SafeArea(
                    top: false,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
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
                                      Row(
                                        children: [
                                          _buildNavItem(Icons.space_dashboard_rounded, 'Home', 0, dark),
                                          _buildNavItem(Icons.calendar_month_rounded, 'Routine', 1, dark),
                                        ],
                                      ),
                                      const Spacer(),
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
                        Positioned(
                          bottom: 45,
                          child: _buildCenterButton(Icons.forum_rounded, 2, dark),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
                ),
              )
            : const SizedBox.shrink(),
      ),
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
              Color(0xFFEC4899),
              primaryColor,
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
