import 'dart:ui';
import 'dart:math' as math;
import 'package:eduvian/model/ArrowTooltip.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/notification_service.dart';

import 'department.dart';

// ==========================================
// NEW DESIGN SYSTEM (Glassmorphism & Gradients)
// ==========================================
bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

// ==========================================
// ACADEMIC INFO PARSER
// ==========================================

/// Parsed representation of a batch code like "7DCSE.2" or "7DCSE" (no section)
class AcademicInfo {
  /// e.g. 7
  final int semester;

  /// e.g. "CSE" (always uppercase)
  final String department;

  /// e.g. 2 — null means no multi-section (single section only)
  final int? section;

  const AcademicInfo({
    required this.semester,
    required this.department,
    this.section,
  });

  /// Returns the canonical compact string, e.g. "7DCSE.2" or "7DCSE"
  @override
  String toString() {
    final base = '${semester}D$department';
    return section != null ? '$base.$section' : base;
  }
}

/// Parses a batch code string into an [AcademicInfo].
///
/// • Accepts any case — input is uppercased before parsing.
/// • Section suffix (`.N`) is optional.
///
/// Examples:
///   "7DCSE.2"  →  semester=7, department="CSE", section=2
///   "7dcse"    →  semester=7, department="CSE", section=null
///
/// Returns `null` if the string does not match the expected format.
AcademicInfo? parseAcademicInfo(String raw) {
  // Uppercase first so lowercase letters (e.g. "cse") are accepted.
  final upper = raw.trim().toUpperCase();

  // Spacer letter is matched but NOT captured.
  // Section suffix ".N" is optional.
  final pattern = RegExp(r'^(\d+)[A-Z]([A-Z]+)(?:\.(\d+))?$');
  final match = pattern.firstMatch(upper);
  if (match == null) return null;

  return AcademicInfo(
    semester:   int.parse(match.group(1)!),
    department: match.group(2)!,
    section:    match.group(3) != null ? int.parse(match.group(3)!) : null,
  );
}

const primaryColor = Color.fromRGBO(107, 0, 50, 1);
const secondaryColor = Color.fromRGBO(209, 61, 89, 1); // vibrant maroon accent
const offWhite = Color.fromRGBO(255, 249, 242, 1);
final glassWhite = Colors.white.withValues(alpha: 0.4);
final glassShadow = Colors.black.withValues(alpha: 0.05);

class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

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
          SafeArea(child: widget.child),
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
      paint.color = Colors.white.withOpacity(baseOpacity * (0.25 + 0.75 * twinkleVal));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarrySkyPainter oldDelegate) => oldDelegate.twinkle != twinkle;
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double alpha;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.alpha = 0.5,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: dark ? Colors.black.withValues(alpha: alpha * 0.7) : Colors.white.withValues(alpha: alpha),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? (dark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withValues(alpha: 0.2) : glassShadow,
                  blurRadius: 24,
                  spreadRadius: -4,
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

AppBar appBar(BuildContext context, String title) {
  final dark = isDark(context);
  final textColor = dark ? Colors.white : primaryColor;
  
  return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      leading: GoRouter.of(context).canPop()
          ? IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
            )
          : null,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: dark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
}

// ==========================================
// UPDATED LEGACY WIDGETS
// ==========================================

class RoundedField extends StatelessWidget {
  final Widget child;
  const RoundedField({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      alpha: 0.6,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

InputDecoration inputDecoration() => InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class DropdownField extends ConsumerWidget {
  final StateProvider<String?> ProviderName;
  final List<String> item;
  final String? hintText;
  final void Function(WidgetRef ref, String?)? onChangeExtra;
  const DropdownField({
    super.key,
    required this.ProviderName,
    required this.item,
    this.hintText,
    this.onChangeExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectValue = ref.watch(ProviderName);
    final dark = isDark(context);
    return DropdownButtonFormField<String>(
      initialValue: selectValue,
      decoration: inputDecoration(),
      dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? Colors.white70 : primaryColor),
      style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      borderRadius: BorderRadius.circular(16),
      items: [
        if (hintText != null)
          DropdownMenuItem<String>(
            value: null,
            child: Text(hintText!, style: TextStyle(color: dark ? Colors.white54 : Colors.black45)),
          ),
        ...item.map((value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
      ],
      onChanged: (newValue) {
        ref.read(ProviderName.notifier).state = newValue;
        if (onChangeExtra != null) {
          onChangeExtra!(ref, newValue);
        }
      },
    );
  }
}

InputDecoration fieldDecoration(BuildContext context, {String? hint, IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: isDark(context) ? Colors.white54 : Colors.black45),
      prefixIcon: icon != null ? Icon(icon, color: primaryColor.withValues(alpha: 0.7)) : null,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class SubjectAutoComplete extends ConsumerWidget {
  final StateProvider<String?> departmentProvider;
  final Map<String?, List<Subject>> departmentMap;
  final StateProvider<List<Subject>> subjectProvider;
  final InputDecoration Function(BuildContext context, {String? hint, IconData? icon}) fieldDecoration;

  const SubjectAutoComplete({
    super.key,
    required this.departmentProvider,
    required this.departmentMap,
    required this.subjectProvider,
    required this.fieldDecoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<Subject>(
      optionsBuilder: (TextEditingValue subjectName) {
        final departmentf = ref.watch(departmentProvider);
        final departmentList = departmentMap[departmentf] ?? [];
        if (departmentf == '') {
          return const Iterable<Subject>.empty();
        }
        if (subjectName.text.trim().isEmpty) {
          return departmentList;
        }
        return departmentList.where(
          (subject) =>
              subject.Code.toLowerCase().contains(subjectName.text.toLowerCase()) ||
              subject.Title.toLowerCase().contains(subjectName.text.toLowerCase()),
        );
      },
      displayStringForOption: (Subject option) => '${option.Code} ${option.Title}',
      fieldViewBuilder: (context, controller, focuseNode, onEditingComplete) {
        final dark = isDark(context);
        return TextField(
          controller: controller,
          focusNode: focuseNode,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: dark ? Colors.white : Colors.black87),
          onTap: () {
            controller.clear();
            controller.selection = TextSelection.collapsed(offset: controller.text.length);
          },
          onEditingComplete: onEditingComplete,
          decoration: fieldDecoration(
            context,
            hint: 'Search Subject',
            icon: Icons.search,
          ),
        );
      },
      onSelected: (Subject subjects) {
        final current = ref.read(subjectProvider);
        if (!current.contains(subjects)) {
          ref.read(subjectProvider.notifier).state = [...current, subjects];
        }
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16),
            color: isDark(context) ? const Color(0xFF2C2C32) : Colors.white,
            shadowColor: isDark(context) ? Colors.black54 : glassShadow,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: ((options.length * 55.0).clamp(0, 5 * 55.0)),
                maxWidth: (MediaQuery.of(context).size.width) * 0.90,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(
                      option.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600,
                        color: isDark(context) ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () => onSelected(option),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    hoverColor: isDark(context) ? Colors.white12 : Colors.blueGrey.shade50,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// DATA MAPS & PROVIDERS
// ==========================================

final gradeToPoint = {
  'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0, 'B-': 2.7,
  'C+': 2.3, 'C': 2.0, 'C-': 1.7, 'D+': 1.3, 'D': 1.0, 'F': 0.0,
};
final semester = {
  "Semester 1", "Semester 2", "Semester 3", "Semester 4", "Semester 5", "Semester 6",
  "Semester 7", "Semester 8", "Semester 9", "Semester 10", "Semester 11", "Semester 12",
};
final creditTo = ["1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6"];

final GlobalKey<ArrowTooltipState> gradeKey = GlobalKey();
final GlobalKey<ArrowTooltipState> creditKey = GlobalKey();
final dialogGradeProvider = StateProvider<String?>((ref) => null);
final dialogCreditProvider = StateProvider<String>((ref) => '');

void showTooltip(GlobalKey<ArrowTooltipState> key) {
  final dynamic tooltip = key.currentState;
  tooltip?.ensureTooltipVisible();
}

void showAddSubjectDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) {
      final dark = isDark(context);
      return AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Custom Subject', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            color: dark ? Colors.white : primaryColor
          )
        ),
        content: Consumer(
          builder: (context, ref, child) {
            final selectGrade = ref.watch(dialogCreditProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundedField(
                  child: ArrowTooltip(
                    key: creditKey,
                    arrowPosition: 'topCenter',
                    backgroundColor: Colors.blueAccent,
                    textColor: Colors.white,
                    message: "Please select a Credit",
                    child: DropdownButtonFormField<String>(
                      initialValue: selectGrade.isNotEmpty ? selectGrade : null,
                      decoration: const InputDecoration(
                        hintText: "Credit",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: InputBorder.none,
                      ),
                      dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
                      items: creditTo.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(c, style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87))
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) ref.read(dialogCreditProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                RoundedField(
                  child: ArrowTooltip(
                    key: gradeKey,
                    arrowPosition: 'bottomCenter',
                    message: "Please select a grade",
                    child: DropdownButtonFormField<String>(
                      initialValue: gradeToPoint.keys.contains(selectGrade) ? selectGrade : null,
                      decoration: const InputDecoration(
                        hintText: "Grade",
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: InputBorder.none,
                      ),
                      dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
                      items: gradeToPoint.keys.map((g) => DropdownMenuItem(
                        value: g, 
                        child: Text(g, style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87))
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) ref.read(dialogGradeProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final grade = ref.read(dialogGradeProvider);
              final creditStr = ref.read(dialogCreditProvider);
              final credit = double.tryParse(creditStr);
              bool hasError = false;
              if (grade == null || grade.trim().isEmpty) {
                showTooltip(gradeKey);
                hasError = true;
              }
              if (creditStr.trim().isEmpty || credit == null) {
                showTooltip(creditKey);
                hasError = true;
              }
              if (!hasError) {
                final currentSubjects = ref.read(subjectProvider);
                final newSubject = Subject("Manual-${currentSubjects.length + 1}", "Custom Subject", credit!);
                ref.read(subjectProvider.notifier).state = [...currentSubjects, newSubject];
                final currentGrades = ref.read(gradeProvider);
                ref.read(gradeProvider.notifier).state = {...currentGrades, newSubject.Code: grade!};
                ref.read(dialogGradeProvider.notifier).state = null;
                ref.read(dialogCreditProvider.notifier).state = '';
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

final semesterProvider = StateProvider<String?>((ref) => null);

/// Converts a 24-hour "HH:mm" string to a 12-hour "h:mm a" string.
String format12Hour(String time24) {
  final parts = time24.split(':');
  if (parts.length < 2) return time24;
  int hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1];
  final period = hour >= 12 ? 'PM' : 'AM';
  if (hour == 0) hour = 12;
  else if (hour > 12) hour -= 12;
  return '$hour:$minute $period';
}

// ══════════════════════════════════════════════════════════════════════════════
// ACADEMIC INFO SETUP DIALOG  (shown once for new users)
// ══════════════════════════════════════════════════════════════════════════════

/// Shows the first-time academic info setup dialog.
/// Returns `true` if the user saved, `false` if they cancelled.
Future<bool> showAcademicInfoSetupDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => const _AcademicInfoSetupDialog(),
  );
  return result == true;
}

class _AcademicInfoSetupDialog extends StatefulWidget {
  const _AcademicInfoSetupDialog();

  @override
  State<_AcademicInfoSetupDialog> createState() =>
      _AcademicInfoSetupDialogState();
}

class _AcademicInfoSetupDialogState extends State<_AcademicInfoSetupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final _textController = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scaleAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _textController.text.trim().toUpperCase();
    if (raw.isEmpty) return;

    if (parseAcademicInfo(raw) == null) {
      setState(() => _errorText = 'Invalid format. Use e.g. 7DCSE.2');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_info', raw);
    
    // Subscribe to new topic for notifications
    await NotificationService().subscribeToBatchTopic(raw);
    
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A0A14) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: dark
                    ? primaryColor.withValues(alpha: 0.35)
                    : primaryColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: dark ? 0.25 : 0.12),
                  blurRadius: 40,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Icon ───────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                const Color(0xFF3B1F8F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Title ──────────────────────────────────────────────
                      Text(
                        'Set Up Your Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF1A0A14),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your academic info to personalise your routine. You can change this anytime in Settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: dark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Single Text Field ──────────────────────────────────
                      _label('ACADEMIC INFO', dark),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        style: GoogleFonts.inter(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. 7DCSE.2',
                          hintStyle: GoogleFonts.inter(
                            color: dark ? Colors.white38 : Colors.black38,
                          ),
                          errorText: _errorText,
                          filled: true,
                          fillColor: dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: primaryColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (_errorText != null) {
                              _errorText = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Action Buttons ─────────────────────────────────────
                      Row(
                        children: [
                          // Cancel
                          Expanded(
                            child: TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Skip for now',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      dark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save
                          Expanded(
                            flex: 2,
                            child: AnimatedOpacity(
                              opacity: _textController.text.trim().isNotEmpty ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed: (_textController.text.trim().isNotEmpty && !_saving) ? _save : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      primaryColor.withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 4,
                                  shadowColor:
                                      primaryColor.withValues(alpha: 0.4),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Save & Continue',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
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
        ),
      ),
    );
  }

  Widget _label(String text, bool dark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: dark ? Colors.white54 : Colors.black45,
        ),
      );
}

class _PickerDropdown<T> extends StatelessWidget {
  final bool dark;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PickerDropdown({
    required this.dark,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: dark ? const Color(0xFF24101C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: dark ? Colors.white54 : primaryColor.withValues(alpha: 0.7)),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: dark ? Colors.white : const Color(0xFF1A0A14),
          ),
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: dark ? Colors.white30 : Colors.black38,
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
