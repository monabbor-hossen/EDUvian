import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/subject_autocomplete.dart';
import '../../domain/entities/subject.dart';
import '../providers/calculator_providers.dart';

class GpaCalculation extends ConsumerStatefulWidget {
  const GpaCalculation({super.key});

  @override
  ConsumerState<GpaCalculation> createState() => _GpaCalculationState();
}

class _GpaCalculationState extends ConsumerState<GpaCalculation> {
  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider);
    final gpa = ref.watch(gpaProvider);

    return AppBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark(context) ? Colors.white : primaryColor,
          title: Text(
            'GPA Calculator',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Select Department',
                  style: GoogleFonts.inter(
                    color: isDark(context) ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    return RoundedField(
                      child: DropdownField(
                        ProviderName: departmentProvider,
                        item: department.keys.toList(),
                        hintText: "Choose a department",
                        onChangeExtra: (ref, newValue) {
                          ref.watch(subjectProvider.notifier).state = [];
                        },
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1);
                  },
                ),
                const SizedBox(height: 16),
                if (ref.watch(departmentProvider) != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RoundedField(
                          child: SubjectAutoComplete(
                            departmentProvider: departmentProvider,
                            departmentMap: department,
                            subjectProvider: subjectProvider,
                            fieldDecoration: (context, {hint, icon}) => fieldDecoration(context, hint: hint, icon: icon),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => showAddSubjectDialog(context, ref),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(16),
                          child: const Icon(Icons.add_rounded, color: primaryColor, size: 28),
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                subject.Code,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.Title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark(context) ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Cr: ${subject.Credit}",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: isDark(context) ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isDark(context) ? Colors.white10 : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark(context) ? Colors.white24 : Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ref.watch(gradeProvider)[subject.Code],
                                    hint: Text("Gr", style: GoogleFonts.inter(color: isDark(context) ? Colors.white54 : Colors.black45)),
                                    dropdownColor: isDark(context) ? const Color(0xFF2C2C32) : Colors.white,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                                    items: gradeToPoint.keys.map((grade) {
                                      return DropdownMenuItem(
                                        value: grade,
                                        child: Text(grade, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark(context) ? Colors.white : Colors.black87)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      final current = ref.read(gradeProvider);
                                      ref.read(gradeProvider.notifier).state = {
                                        ...current,
                                        subject.Code: value ?? '',
                                      };
                                    },
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () {
                                final update = ref.read(subjectProvider.notifier).state..remove(subject);
                                ref.read(subjectProvider.notifier).state = [...update];
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2);
                    },
                  ),
                ),
                
                if (subjects.isNotEmpty)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    padding: const EdgeInsets.all(20),
                    borderColor: primaryColor.withValues(alpha: 0.3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total GPA",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark(context) ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          gpa.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark(context) ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
