import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/calculator/domain/entities/subject.dart';
import '../../features/calculator/presentation/providers/calculator_providers.dart';
import '../theme/app_theme.dart';
import 'arrow_tooltip.dart';
import 'rounded_field.dart';

final GlobalKey<ArrowTooltipState> gradeKey = GlobalKey();
final GlobalKey<ArrowTooltipState> creditKey = GlobalKey();
final dialogGradeProvider = StateProvider<String?>((ref) => null);
final dialogCreditProvider = StateProvider<String>((ref) => '');

final creditTo = ["1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6"];

void showTooltip(GlobalKey<ArrowTooltipState> key) {
  final dynamic tooltip = key.currentState;
  tooltip?.ensureTooltipVisible();
}

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
        final glassShadowColor = isDark(context) ? Colors.black54 : const Color(0x1B000000);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16),
            color: isDark(context) ? const Color(0xFF2C2C32) : Colors.white,
            shadowColor: glassShadowColor,
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
