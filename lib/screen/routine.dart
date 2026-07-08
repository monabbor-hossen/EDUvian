import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/auth_service.dart';
import '../model/department.dart';
import '../model/routine.dart';
import '../model/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTINE MANAGER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RoutineManagerScreen extends ConsumerStatefulWidget {
  const RoutineManagerScreen({super.key});

  @override
  ConsumerState<RoutineManagerScreen> createState() =>
      _RoutineManagerScreenState();
}

class _RoutineManagerScreenState extends ConsumerState<RoutineManagerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Start on today's tab
    final todayIndex = kDays.indexOf(todayName);
    _tabController = TabController(
      length: kDays.length,
      vsync: this,
      initialIndex: todayIndex < 0 ? 0 : todayIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.asData?.value != null;

    if (!isLoggedIn) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Class Routine',
              style: GoogleFonts.poppins(
                color: dark ? Colors.white : primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 64,
                      color: primaryColor.withValues(alpha: 0.5),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 24),
                    Text(
                      'Login Required',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please log in to manage your class routine and schedule.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: dark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Go to Login',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final routineAsync = ref.watch(routineProvider);
    final batchId = ref.watch(batchIdProvider);
    final rawAcademicInfo = ref.watch(academicInfoProvider).valueOrNull;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(dark, rawAcademicInfo),
        floatingActionButton: _buildFab(dark),
        body: routineAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (routine) => Column(
            children: [
              // ── Tab Bar ──────────────────────────────────────────────
              _DayTabBar(controller: _tabController, dark: dark),
              // ── Tab Views ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: kDays.map((day) {
                    final classes = routine[day] ?? [];
                    return _DayTabBody(
                      day: day,
                      classes: classes,
                      dark: dark,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool dark, String? batchId) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            'Class Routine',
            style: GoogleFonts.poppins(
              color: dark ? Colors.white : primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          if (batchId != null)
            Text(
              batchId,
              style: GoogleFonts.inter(
                color: dark ? Colors.white54 : Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildFab(bool dark) {
    return FloatingActionButton.extended(
      onPressed: () => _showClassDialog(context, ref,
          kDays[_tabController.index]),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text('Add Class',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _DayTabBar extends StatelessWidget {
  final TabController controller;
  final bool dark;

  const _DayTabBar({required this.controller, required this.dark});

  static const _abbrev = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: dark ? Colors.white54 : Colors.black45,
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        tabs: List.generate(
          kDays.length,
          (i) {
            final isToday = kDays[i] == todayName;
            return Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_abbrev[i]),
                    if (isToday) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY TAB BODY
// ─────────────────────────────────────────────────────────────────────────────

class _DayTabBody extends ConsumerWidget {
  final String day;
  final List<ClassEntry> classes;
  final bool dark;

  const _DayTabBody({
    required this.day,
    required this.classes,
    required this.dark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (classes.isEmpty) {
      return _EmptyDayView(day: day, dark: dark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final entry = classes[index];
        return _ClassCard(
          entry: entry,
          day: day,
          dark: dark,
          index: index,
        ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ClassCard extends ConsumerWidget {
  final ClassEntry entry;
  final String day;
  final bool dark;
  final int index;

  const _ClassCard({
    required this.entry,
    required this.day,
    required this.dark,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(routineServiceProvider);
    final isToday = day == todayName;
    final ongoing = isToday && entry.isOngoing;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: ongoing
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.85),
                  const Color(0xFF3B1F8F).withValues(alpha: 0.75),
                ],
              )
            : null,
        color: ongoing
            ? null
            : (dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7)),
        border: Border.all(
          color: ongoing
              ? Colors.white.withValues(alpha: 0.2)
              : (dark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
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
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format12Hour(entry.startTime),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ongoing ? Colors.white : (dark ? Colors.white70 : primaryColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format12Hour(entry.endTime),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ongoing
                          ? Colors.white60
                          : (dark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
            // Divider line
            Container(
              width: 2,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ongoing
                    ? Colors.white38
                    : primaryColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Details
            Expanded(
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (entry.room.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: entry.room,
                      light: ongoing,
                      dark: dark,
                    ),
                  if (entry.teacher.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: entry.teacher,
                      light: ongoing,
                      dark: dark,
                    ),
                  ],
                ],
              ),
            ),
            // Action icons
            Column(
              children: [
                _IconBtn(
                  icon: Icons.edit_rounded,
                  color: ongoing ? Colors.white70 : primaryColor,
                  onTap: () => _showClassDialog(context, ref, day, existing: entry),
                ),
                const SizedBox(height: 4),
                _IconBtn(
                  icon: Icons.delete_rounded,
                  color: ongoing ? Colors.white54 : Colors.redAccent,
                  onTap: () => _confirmDelete(context, service, day, entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, RoutineService service, String day, ClassEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dark = isDark(ctx);
        return AlertDialog(
          backgroundColor:
              dark ? const Color(0xFF1E1E24) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Class',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : primaryColor,
            ),
          ),
          content: Text(
            'Remove "${entry.subject}" from $day?',
            style: GoogleFonts.inter(
                color: dark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await service.deleteClass(day, entry.id);
                } catch (e) {
                  if (context.mounted) {
                    _showError(context, e.toString());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool light;
  final bool dark;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.light,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final color =
        light ? Colors.white70 : (dark ? Colors.white54 : Colors.black54);
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 12, color: color, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _EmptyDayView extends StatelessWidget {
  final String day;
  final bool dark;

  const _EmptyDayView({required this.day, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 64,
            color: primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No classes on $day',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a class.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: dark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Something went wrong',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD / EDIT CLASS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

void _showClassDialog(
  BuildContext context,
  WidgetRef ref,
  String day, {
  ClassEntry? existing,
}) {
  showDialog(
    context: context,
    builder: (ctx) => _ClassDialog(day: day, existing: existing, ref: ref),
  );
}

class _ClassDialog extends StatefulWidget {
  final String day;
  final ClassEntry? existing;
  final WidgetRef ref;

  const _ClassDialog(
      {required this.day, required this.existing, required this.ref});

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  final _subjectCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  String _startTime = '08:00';
  String _endTime = '09:30';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _subjectCtrl.text = widget.existing!.subject;
      _roomCtrl.text = widget.existing!.room;
      _teacherCtrl.text = widget.existing!.teacher;
      _startTime = widget.existing!.startTime;
      _endTime = widget.existing!.endTime;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _roomCtrl.dispose();
    _teacherCtrl.dispose();
    super.dispose();
  }

  String _formatTOD(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTOD(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTOD(isStart ? _startTime : _endTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = _formatTOD(picked);
        } else {
          _endTime = _formatTOD(picked);
        }
      });
    }
  }

  Future<void> _save() async {
    final subject = _subjectCtrl.text.trim();
    if (subject.isEmpty) {
      _showError(context, 'Subject name is required.');
      return;
    }

    setState(() => _saving = true);
    final service = widget.ref.read(routineServiceProvider);
    final isEdit = widget.existing != null;

    final entry = ClassEntry(
      id: isEdit ? widget.existing!.id : '',
      subject: subject,
      startTime: _startTime,
      endTime: _endTime,
      room: _roomCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
    );

    try {
      if (isEdit) {
        await service.updateClass(widget.day, entry);
      } else {
        await service.addClass(widget.day, entry);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: dark ? const Color(0xFF1E1E24) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        isEdit ? 'Edit Class' : 'Add New Class',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: dark ? Colors.white : primaryColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SubjectAutocompleteField(
              controller: _subjectCtrl,
              label: 'Subject *',
              icon: Icons.book_rounded,
              dark: dark,
              ref: widget.ref,
            ),
            const SizedBox(height: 12),
            // Time row
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Start',
                    time: _startTime,
                    dark: dark,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'End',
                    time: _endTime,
                    dark: dark,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DialogField(
              controller: _roomCtrl,
              label: 'Room (optional)',
              icon: Icons.location_on_rounded,
              dark: dark,
            ),
            const SizedBox(height: 12),
            _DialogField(
              controller: _teacherCtrl,
              label: 'Teacher (optional)',
              icon: Icons.person_rounded,
              dark: dark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: GoogleFonts.inter(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Add',
                  style:
                      GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool dark;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
            color: dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
              color: dark ? Colors.white54 : Colors.black45, fontSize: 13),
          prefixIcon: Icon(icon,
              size: 18,
              color: primaryColor.withValues(alpha: 0.7)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final bool dark;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 16,
                color: primaryColor.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: dark ? Colors.white38 : Colors.black38)),
                Text(format12Hour(time),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR SNACKBAR HELPER
// ─────────────────────────────────────────────────────────────────────────────

void _showError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.redAccent.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(message,
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
    ),
  );
}

class _SubjectAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool dark;
  final WidgetRef ref;

  const _SubjectAutocompleteField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.dark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the subject list based on the user's department
    final academicInfoRaw = ref.read(academicInfoProvider).valueOrNull ?? '';
    final parsed = parseAcademicInfo(academicInfoRaw);
    final deptName = parsed?.department ?? 'CSE';
    final subjects = department[deptName] ?? cseSubjects;

    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Autocomplete<Subject>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Subject>.empty();
          }
          final query = textEditingValue.text.toLowerCase();
          return subjects.where((Subject option) {
            return option.Title.toLowerCase().contains(query) ||
                option.Code.toLowerCase().contains(query);
          });
        },
        displayStringForOption: (Subject option) => option.Title,
        fieldViewBuilder: (BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted) {
          
          // Pre-fill if editing an existing class
          if (controller.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
            fieldTextEditingController.text = controller.text;
          }
          
          // Sync changes from the autocomplete controller back to the dialog controller
          fieldTextEditingController.addListener(() {
            controller.text = fieldTextEditingController.text;
          });

          return TextField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            style: GoogleFonts.inter(
                color: dark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(
                  color: dark ? Colors.white54 : Colors.black45, fontSize: 13),
              prefixIcon: Icon(icon,
                  size: 18, color: primaryColor.withValues(alpha: 0.7)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 128,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF2A2A35) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(
                        option.Title,
                        style: GoogleFonts.inter(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        option.Code,
                        style: GoogleFonts.inter(
                          color: dark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
        onSelected: (Subject selection) {
          controller.text = selection.Title;
        },
      ),
    );
  }
}
