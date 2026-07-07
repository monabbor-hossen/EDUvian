import 'dart:ui';
import 'package:eduvian/model/ArrowTooltip.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'department.dart';

// ==========================================
// NEW DESIGN SYSTEM (Glassmorphism & Gradients)
// ==========================================
bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

const primaryColor = Color.fromRGBO(107, 0, 50, 1);
const secondaryColor = Color.fromRGBO(209, 61, 89, 1); // vibrant maroon accent
const offWhite = Color.fromRGBO(255, 249, 242, 1);
final glassWhite = Colors.white.withValues(alpha: 0.4);
final glassShadow = Colors.black.withValues(alpha: 0.05);

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF121212) : null,
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E24), // Midnight Charcoal
                  Color(0xFF15151A), // Deep Slate
                  Color(0xFF0F0F13), // Deepest Void
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F9FA), // Clean crisp white-gray
                  Color(0xFFE9ECEF), // Sophisticated light slate
                  Color(0xFFDEE2E6), // Cool gray depth
                ],
              ),
      ),
      child: child,
    );
  }
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
