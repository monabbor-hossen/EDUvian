import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../model/routine.dart';
import '../model/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = isDark(context);
    final now = DateTime.now();
    final routineAsync = ref.watch(routineProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _DashboardHeader(dark: dark, now: now),
              ),
              // ── Today's Schedule Title ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Schedule",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            todayName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: dark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/routine'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit_calendar_rounded,
                                  size: 15, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                'Manage',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),
              ),
              // ── Schedule List ─────────────────────────────────────────
              routineAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: _SkeletonList(dark: dark),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: _ErrorCard(dark: dark),
                ),
                data: (routine) {
                  final classes = routine[todayName] ?? [];
                  if (classes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyTodayView(dark: dark),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = classes[index];
                          return _TodayClassCard(
                            entry: entry,
                            dark: dark,
                            index: index,
                            isLast: index == classes.length - 1,
                          );
                        },
                        childCount: classes.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final bool dark;
  final DateTime now;

  const _DashboardHeader({required this.dark, required this.now});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Date block
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, Color(0xFF3B1F8F)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    now.day.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(now),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(now),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy').format(now),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: dark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Academic Day',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY'S CLASS CARD  (timeline style)
// ─────────────────────────────────────────────────────────────────────────────

class _TodayClassCard extends StatelessWidget {
  final ClassEntry entry;
  final bool dark;
  final int index;
  final bool isLast;

  const _TodayClassCard({
    required this.entry,
    required this.dark,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final ongoing = entry.isOngoing;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  format12Hour(entry.startTime),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ongoing
                        ? primaryColor
                        : (dark ? Colors.white54 : Colors.black45),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: ongoing
                          ? primaryColor.withValues(alpha: 0.5)
                          : (dark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
                if (!isLast)
                  Text(
                    format12Hour(entry.endTime),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: dark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: ongoing
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          const Color(0xFF3B1F8F),
                        ],
                      )
                    : null,
                color: ongoing
                    ? null
                    : (dark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.8)),
                border: Border.all(
                  color: ongoing
                      ? Colors.white.withValues(alpha: 0.2)
                      : (dark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.07)),
                  width: 1.2,
                ),
                boxShadow: ongoing
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.subject,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ongoing
                                  ? Colors.white
                                  : (dark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        if (ongoing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'NOW',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (entry.room.isNotEmpty)
                          _InfoPill(
                            icon: Icons.location_on_rounded,
                            label: entry.room,
                            light: ongoing,
                            dark: dark,
                          ),
                        if (entry.teacher.isNotEmpty)
                          _InfoPill(
                            icon: Icons.person_rounded,
                            label: entry.teacher,
                            light: ongoing,
                            dark: dark,
                          ),
                        _InfoPill(
                          icon: Icons.schedule_rounded,
                          label:
                              '${format12Hour(entry.startTime)} – ${format12Hour(entry.endTime)}',
                          light: ongoing,
                          dark: dark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.08),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool light;
  final bool dark;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.light,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        light ? Colors.white70 : (dark ? Colors.white54 : Colors.black54);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: color, height: 1.2)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / LOADING / ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTodayView extends StatelessWidget {
  final bool dark;
  const _EmptyTodayView({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Text('🎉', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No classes today!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free day, or add classes\nvia Manage Routine.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: dark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  final bool dark;
  const _SkeletonList({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 1200.ms,
                color: dark ? Colors.white12 : Colors.black12,
                delay: (i * 200).ms,
              ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final bool dark;
  const _ErrorCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: Colors.redAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Could not load routine.\nCheck your connection.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
