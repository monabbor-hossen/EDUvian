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

class _RoutineManagerScreenState extends ConsumerState<RoutineManagerScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
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
        appBar: _buildAppBar(dark, rawAcademicInfo, _selectedDate),
        floatingActionButton: _buildFab(dark, batchId),
        body: routineAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (routine) => Column(
            children: [
              // ── Date Scroller ─────────────────────────────────────────
              _DateScroller(
                currentMonth: _currentMonth,
                selectedDate: _selectedDate,
                dark: dark,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                onMonthChanged: (month) {
                  setState(() {
                    _currentMonth = month;
                  });
                },
              ),
              // ── Tab View (Now single list based on selected date) ──────
              Expanded(
                child: Builder(
                  builder: (context) {
                    final dayString = kDays[_selectedDate.weekday % 7];
                    final classes = routine[dayString] ?? [];
                    return _DayTabBody(
                      day: dayString,
                      classes: classes,
                      dark: dark,
                      selectedDate: _selectedDate,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool dark, String? batchId, DateTime selectedDate) {
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  batchId,
                  style: GoogleFonts.inter(
                    color: dark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Week ${weekTypeFor(selectedDate)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildFab(bool dark, String? batchId) {
    return FloatingActionButton.extended(
      onPressed: () {
        final dayStr = kDays[_selectedDate.weekday % 7];
        _showClassDialog(context, ref, dayStr);
      },
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
// DATE SCROLLER
// ─────────────────────────────────────────────────────────────────────────────

class _DateScroller extends StatefulWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final bool dark;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _DateScroller({
    required this.currentMonth,
    required this.selectedDate,
    required this.dark,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<_DateScroller> createState() => _DateScrollerState();
}

class _DateScrollerState extends State<_DateScroller> {
  late ScrollController _scrollController;
  final double _itemWidth = 64.0; // width of each date capsule + margin

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(_DateScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth != widget.currentMonth ||
        oldWidget.selectedDate != widget.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate();
      });
    }
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;
    
    // Only scroll if the selected date is in the currently viewed month
    if (widget.selectedDate.year == widget.currentMonth.year && 
        widget.selectedDate.month == widget.currentMonth.month) {
      final targetPosition = (widget.selectedDate.day - 1) * _itemWidth;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final offset = targetPosition.clamp(0.0, maxExtent);
      
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _daysInMonth {
    final date = widget.currentMonth;
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _changeMonth(int offset) {
    final newMonth = DateTime(
      widget.currentMonth.year,
      widget.currentMonth.month + offset,
      1,
    );
    widget.onMonthChanged(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _daysInMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(widget.currentMonth.month)} ${widget.currentMonth.year}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.dark ? Colors.white : primaryColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: widget.dark ? Colors.white70 : primaryColor),
                    onPressed: () => _changeMonth(-1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: widget.dark ? Colors.white70 : primaryColor),
                    onPressed: () => _changeMonth(1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Horizontal Date List
        SizedBox(
          height: 90,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: daysCount,
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final date = DateTime(widget.currentMonth.year, widget.currentMonth.month, dayNum);
              final dayStr = kDays[date.weekday % 7];
              final abbrev = dayStr.substring(0, 3).toUpperCase();
              
              final isSelected = date.year == widget.selectedDate.year &&
                                 date.month == widget.selectedDate.month &&
                                 date.day == widget.selectedDate.day;

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _itemWidth - 10,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? primaryColor 
                        : (widget.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected 
                          ? primaryColor 
                          : (widget.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ] : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNum.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isSelected 
                              ? Colors.white 
                              : (widget.dark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        abbrev,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white.withValues(alpha: 0.8) 
                              : (widget.dark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
  final DateTime selectedDate;

  const _DayTabBody({
    required this.day,
    required this.classes,
    required this.dark,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter: show every-week classes + classes matching the selected week type
    final filtered = classes.where((c) => c.isThisWeekFor(selectedDate)).toList();

    if (filtered.isEmpty) {
      return _EmptyDayView(day: day, dark: dark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _ClassCard(
          entry: entry,
          day: day,
          dark: dark,
          index: index,
          selectedDate: selectedDate,
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
  final DateTime selectedDate;

  const _ClassCard({
    required this.entry,
    required this.day,
    required this.dark,
    required this.index,
    required this.selectedDate,
  });

  String _formatDate(DateTime d) => 
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(routineServiceProvider);
    final isToday = day == todayName;
    final ongoing = isToday && entry.isOngoing;
    
    final dateStr = _formatDate(selectedDate);
    final eventText = entry.getEventText(dateStr);
    final startTime = entry.getEventStartTime(dateStr) ?? entry.startTime;
    final endTime = entry.getEventEndTime(dateStr) ?? entry.endTime;
    final room = entry.getEventRoom(dateStr) ?? entry.room;

    final hasEvent = eventText != null || entry.getEventStartTime(dateStr) != null || entry.getEventEndTime(dateStr) != null || entry.getEventRoom(dateStr) != null;
    
    List<Color> eventColors = [];
    if (hasEvent) {
       final lower = (eventText ?? '').toLowerCase();
       final roomLower = room.toLowerCase();
       
       if (lower.contains('cancel')) eventColors.add(Colors.red);
       if (lower.contains('assignment')) eventColors.add(Colors.blue);
       if (lower.contains('ct') || lower.contains('mid') || lower.contains('test')) eventColors.add(Colors.orange);
       if (roomLower.contains('online') || lower.contains('online')) eventColors.add(Colors.teal);
       
       if (eventColors.isEmpty) {
           eventColors.add(primaryColor);
       }
    }

    final dotColor = ongoing
        ? Colors.white70
        : (dark ? Colors.white60 : primaryColor.withOpacity(0.7));

    final popupMenuButton = Theme(
      data: Theme.of(context).copyWith(
        cardColor: dark ? const Color(0xFF2C2C32) : Colors.white,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top:0, right: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(height: 3),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
        iconSize: 20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: dark ? const Color(0xFF2C2C32) : Colors.white,
        onSelected: (value) {
          if (value == 'edit') {
            _showClassDialog(context, ref, day, existing: entry);
          } else if (value == 'status') {
            _showClassActionSheet(context, ref, day, entry, selectedDate);
          } else if (value == 'delete') {
            _confirmDelete(context, service, day, entry);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: dark ? Colors.white70 : primaryColor),
                const SizedBox(width: 10),
                Text('Edit details', style: GoogleFonts.inter(fontSize: 14, color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'status',
            child: Row(
              children: [
                Icon(Icons.event_note_rounded, size: 18, color: Colors.orange.shade600),
                const SizedBox(width: 10),
                Text('Add day update', style: GoogleFonts.inter(fontSize: 14, color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                const SizedBox(width: 10),
                Text('Delete class', style: GoogleFonts.inter(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => _showClassActionSheet(context, ref, day, entry, selectedDate),
      child: Container(
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
              : (hasEvent && eventColors.length > 1
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: eventColors.map((c) => c.withValues(alpha: dark ? 0.2 : 0.15)).toList(),
                    )
                  : null),
          color: ongoing || (hasEvent && eventColors.length > 1)
              ? null
              : (hasEvent
                  ? eventColors.first.withValues(alpha: dark ? 0.15 : 0.08)
                  : (dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.7))),
          border: Border.all(
            color: ongoing
                ? Colors.white.withValues(alpha: 0.2)
                : (hasEvent
                    ? eventColors.first.withValues(alpha: 0.4)
                    : (dark ? Colors.white12 : Colors.black.withValues(alpha: 0.08))),
            width: 1.2,
          ),
          boxShadow: ongoing
              ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 40, 16),
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
                          format12Hour(startTime),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ongoing ? Colors.white : (dark ? Colors.white70 : primaryColor),
                          ),
                        ),
                        if (entry.getEventStartTime(dateStr) == null) ...[
                          const SizedBox(height: 2),
                          Text(
                            format12Hour(endTime),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ongoing ? Colors.white60 : (dark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Divider line
                  Container(
                    width: 2,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ongoing ? Colors.white38 : primaryColor.withValues(alpha: 0.25),
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
                                  decoration: (eventText?.toLowerCase().contains('cancel') == true)
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: ongoing ? Colors.white : (dark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ),
                            if (entry.weekType != null)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ongoing ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ongoing ? Colors.white38 : primaryColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  'Wk ${entry.weekType}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: ongoing ? Colors.white : primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (ongoing)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        if (room.isNotEmpty)
                          _InfoRow(icon: Icons.location_on_rounded, label: room, light: ongoing, dark: dark),
                        if (entry.teacher.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _InfoRow(icon: Icons.person_rounded, label: entry.teacher, light: ongoing, dark: dark),
                        ],
                        if (eventText != null && eventText.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: eventText
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .map((et) {
                              final lower = et.toLowerCase();
                              Color baseColor = primaryColor;
                              if (lower.contains('cancel')) baseColor = Colors.red;
                              else if (lower.contains('assignment')) baseColor = Colors.blue;
                              else if (lower.contains('ct') || lower.contains('mid') || lower.contains('test')) baseColor = Colors.orange;
                              else if (lower.contains('online')) baseColor = Colors.teal;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: baseColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: baseColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  et,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: baseColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Two-dot popup menu pinned to top-right
            Positioned(
              top: 0,
              right: 0,
              child: popupMenuButton,
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
  final String? tooltip;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
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
// ACTION SHEET
// ─────────────────────────────────────────────────────────────────────────────

void _showClassActionSheet(
  BuildContext context,
  WidgetRef ref,
  String day,
  ClassEntry entry,
  DateTime selectedDate,
) {
  final dark = isDark(context);
  final service = ref.read(routineServiceProvider);
  final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  final initialText = entry.getEventText(dateStr);
  final ctrl = TextEditingController(text: initialText ?? '');
  
  String? overrideStartTime = entry.getEventStartTime(dateStr);
  final roomCtrl = TextEditingController(text: entry.getEventRoom(dateStr) ?? '');
  final roomFocus = FocusNode();

  void _updateStatus(String? status) async {
    Navigator.pop(context);
    final events = entry.dateEvents != null ? Map<String, dynamic>.from(entry.dateEvents!) : <String, dynamic>{};
    
    final hasTimeOrRoom = overrideStartTime != null || roomCtrl.text.trim().isNotEmpty;
    final hasText = status != null && status.trim().isNotEmpty;

    if (!hasText && !hasTimeOrRoom) {
      events.remove(dateStr);
    } else {
      events[dateStr] = {
        if (hasText) 'text': status.trim(),
        if (overrideStartTime != null) 'startTime': overrideStartTime,
        if (roomCtrl.text.trim().isNotEmpty) 'room': roomCtrl.text.trim(),
      };
    }

    // Build a rich, human-readable notification body
    final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final humanDate = '${kDays[selectedDate.weekday % 7]}, ${selectedDate.day} ${monthNames[selectedDate.month - 1]}';
    
    String notificationHint;
    if (!hasText && !hasTimeOrRoom) {
      // Clearing an event
      notificationHint = 'Update cleared for ${entry.subject} on $humanDate.';
    } else {
      final parts = <String>[];
      if (hasText) parts.add(status!.trim());
      if (overrideStartTime != null) parts.add('Time: ${format12Hour(overrideStartTime!)}');
      if (roomCtrl.text.trim().isNotEmpty) parts.add('Room: ${roomCtrl.text.trim()}');
      notificationHint = '${parts.join(' • ')} — ${entry.subject} on $humanDate';
    }
    
    try {
      await service.updateClass(
        day,
        entry.copyWith(dateEvents: events.isEmpty ? null : events),
        notificationHint: notificationHint,
      );
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }
  }

  bool showOverrides = overrideStartTime != null || roomCtrl.text.trim().isNotEmpty;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime() async {
            final currentStr = overrideStartTime ?? entry.startTime;
            TimeOfDay initialTime = TimeOfDay.now();
            if (currentStr.isNotEmpty) {
              final parts = currentStr.split(':');
              if (parts.length == 2) {
                initialTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
              }
            }
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: dark
                      ? const ColorScheme.dark(primary: primaryColor, surface: Color(0xFF1E1E24))
                      : const ColorScheme.light(primary: primaryColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() {
                overrideStartTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E1E24) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Class Options',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Custom text input
                    TextField(
                      controller: ctrl,
                      minLines: 2,
                      maxLines: 4,
                      style: GoogleFonts.inter(
                        color: dark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Any class update? e.g. "Canceled"',
                        hintStyle: GoogleFonts.inter(
                          color: dark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: dark ? Colors.white12 : Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: dark ? Colors.white12 : Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Quick-fill chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Canceled',
                        'Class Test',
                        'Mid',
                        'Assignment',
                        'Online',
                        'Room Change',
                      ].map((text) => ActionChip(
                        label: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: dark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                        side: BorderSide(color: dark ? Colors.white12 : Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          if (text == 'Online') {
                            setState(() {
                              showOverrides = true;
                              roomCtrl.text = 'Online';
                            });
                          } else if (text == 'Room Change') {
                            setState(() {
                              showOverrides = true;
                              roomFocus.requestFocus();
                            });
                          } else {
                            final current = ctrl.text.trim();
                            if (current.isEmpty) {
                              ctrl.text = text;
                            } else {
                              final parts = current.split(',').map((e) => e.trim()).toList();
                              if (parts.contains(text)) {
                                parts.remove(text);
                                ctrl.text = parts.join(', ');
                              } else {
                                ctrl.text = current + (current.endsWith(',') ? ' ' : ', ') + text;
                              }
                            }
                          }
                        },
                      )).toList(),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    
                    InkWell(
                      onTap: () {
                        setState(() {
                          showOverrides = !showOverrides;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Time & Room Override (Optional)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: dark ? Colors.white70 : Colors.black87)),
                            ),
                            Icon(showOverrides ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: dark ? Colors.white54 : Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    
                    if (showOverrides) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: pickTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: dark ? Colors.white12 : Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Custom Time', style: GoogleFonts.inter(fontSize: 10, color: dark ? Colors.white54 : Colors.black54)),
                                          const SizedBox(height: 2),
                                          Text(overrideStartTime != null ? format12Hour(overrideStartTime!) : 'Keep Original', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: overrideStartTime != null ? primaryColor : (dark ? Colors.white : Colors.black87))),
                                        ],
                                      ),
                                    ),
                                    if (overrideStartTime != null)
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            overrideStartTime = null;
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: Colors.redAccent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: roomCtrl,
                        focusNode: roomFocus,
                        style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'New Room (e.g. "Online")',
                          hintStyle: GoogleFonts.inter(color: dark ? Colors.white38 : Colors.black38),
                          filled: true,
                          fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white12 : Colors.black12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? Colors.white12 : Colors.black12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: roomCtrl,
                            builder: (context, value, child) {
                              if (value.text.isEmpty) return const SizedBox.shrink();
                              return IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  roomCtrl.clear();
                                },
                                color: Colors.redAccent,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (initialText != null || overrideStartTime != null || entry.getEventRoom(dateStr) != null) ...[
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(null),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Clear', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(ctrl.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Save Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
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
  /// null = every week, 'A' = odd weeks, 'B' = even weeks
  String? _weekType;
  late String _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.day;
    if (widget.existing != null) {
      _subjectCtrl.text = widget.existing!.subject;
      _roomCtrl.text = widget.existing!.room;
      _teacherCtrl.text = widget.existing!.teacher;
      _startTime = widget.existing!.startTime;
      _endTime = widget.existing!.endTime;
      _weekType = widget.existing!.weekType;
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
    final dark = isDark(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTOD(isStart ? _startTime : _endTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: dark
              ? ColorScheme.dark(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1E1E24),
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
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
      weekType: _weekType,
    );

    try {
      if (isEdit) {
        // If they change the day of an existing class, we might need to delete from old day 
        // and add to new day. For simplicity in the UI, if they change the day, 
        // we'll remove it from the old day and add to the new day.
        if (_selectedDay != widget.day) {
          await service.deleteClass(widget.day, entry.id);
          await service.addClass(_selectedDay, entry);
        } else {
          await service.updateClass(widget.day, entry);
        }
      } else {
        await service.addClass(_selectedDay, entry);
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar (like a bottom sheet) ──────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),

            // ── Title ─────────────────────────────────────────────
            Text(
              isEdit ? 'Edit Class' : 'Add New Class',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: dark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isEdit
                  ? 'Update the details of this class'
                  : 'Fill in the details to add a new class',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: dark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ── Form fields ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Day Selector Chips
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Day',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: kDays.map((day) {
                          final isSelected = _selectedDay == day;
                          final abbrev = day.substring(0, 3).toUpperCase();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (dark
                                        ? Colors.white.withValues(alpha: 0.07)
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (dark ? Colors.white12 : Colors.black12),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                abbrev,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (dark ? Colors.white54 : Colors.black54),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SubjectAutocompleteField(
                      controller: _subjectCtrl,
                      label: 'Subject *',
                      icon: Icons.book_rounded,
                      dark: dark,
                      ref: widget.ref,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    // ── Week type selector ────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Repeats',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _WeekChip(
                          label: 'Every Week',
                          icon: Icons.repeat_rounded,
                          selected: _weekType == null,
                          dark: dark,
                          onTap: () => setState(() => _weekType = null),
                        ),
                        const SizedBox(width: 8),
                        _WeekChip(
                          label: 'Week A',
                          icon: Icons.looks_one_rounded,
                          selected: _weekType == 'A',
                          dark: dark,
                          onTap: () => setState(() => _weekType = 'A'),
                        ),
                        const SizedBox(width: 8),
                        _WeekChip(
                          label: 'Week B',
                          icon: Icons.looks_two_rounded,
                          selected: _weekType == 'B',
                          dark: dark,
                          onTap: () => setState(() => _weekType = 'B'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Buttons row (Cancel | Add) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark ? Colors.white70 : Colors.black54,
                        side: BorderSide(
                          color: dark ? Colors.white24 : Colors.black12,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add / Update button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Yes, Update' : 'Yes, Add',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// WEEK TYPE CHIP (for the Repeats selector in the dialog)
// ─────────────────────────────────────────────────────────────────────────────

class _WeekChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  const _WeekChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : (dark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? primaryColor
                  : (dark ? Colors.white12 : Colors.black12),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (dark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (dark ? Colors.white54 : Colors.black54),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

