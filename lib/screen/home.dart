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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(
                  Icons.settings_rounded,
                  color: isDark(context) ? Colors.white : primaryColor,
                  size: 28,
                ),
              ).animate().scale(delay: 200.ms),
            ),
          ],
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
                const SizedBox(height: 40),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                    children: [
                      _buildLargeCard(
                        context,
                        icon: Icons.attach_money_rounded,
                        label: 'Credit &\nCost',
                        color: const Color(0xFFE84545),
                        onTap: '/credit',
                        delay: 300,
                      ),
                      _buildLargeCard(
                        context,
                        icon: Icons.school_rounded,
                        label: 'GPA\nCalculator',
                        color: const Color(0xFF2B2E4A),
                        onTap: '/gpa',
                        delay: 400,
                      ),
                      _buildLargeCard(
                        context,
                        icon: Icons.workspace_premium_rounded,
                        label: 'CGPA\nCalculator',
                        color: const Color(0xFF903749),
                        onTap: '/cgpa',
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

  Widget _buildLargeCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () => context.push(onTap),
      child: GlassContainer(
        blur: 20,
        alpha: 0.6,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(20),
        borderColor: Colors.white.withValues(alpha: 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isDark(context) ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2).shimmer(delay: (delay + 500).ms, duration: 1000.ms, color: Colors.white.withValues(alpha: 0.5)),
    );
  }
}
