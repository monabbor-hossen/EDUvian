import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/rounded_field.dart';
import '../../../../core/widgets/dropdown_field.dart';
import '../../../../core/widgets/arrow_tooltip.dart';
import '../../domain/entities/subject.dart';
import '../providers/calculator_providers.dart';

class CgpaCalculation extends ConsumerStatefulWidget {
  const CgpaCalculation({super.key});

  @override
  ConsumerState<CgpaCalculation> createState() => _CgpaCalculationState();
}

class _CgpaCalculationState extends ConsumerState<CgpaCalculation> {
  final creditController = TextEditingController();
  final gpaController = TextEditingController();

  final GlobalKey<ArrowTooltipState> creditKey = GlobalKey();
  final GlobalKey<ArrowTooltipState> gradeKey = GlobalKey();

  void showTooltip(GlobalKey<ArrowTooltipState> key) {
    final dynamic tooltip = key.currentState;
    tooltip?.ensureTooltipVisible();
  }

  @override
  void initState() {
    super.initState();
    loadDefaultDepartment(ref);
  }

  @override
  void dispose() {
    creditController.dispose();
    gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark(context) ? Colors.white : primaryColor,
          title: Text(
            'CGPA Calculator',
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
                  'Add Semester Details',
                  style: GoogleFonts.inter(
                    color: isDark(context) ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          return RoundedField(
                            child: DropdownField(
                              ProviderName: departmentProvider,
                              item: department.keys.toList(),
                              hintText: "Department",
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          return RoundedField(
                            child: DropdownField(
                              ProviderName: semesterProvider,
                              item: semester.toList(),
                              hintText: "Semester",
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: RoundedField(
                        child: ArrowTooltip(
                          key: creditKey,
                          message: "Enter valid Credit",
                          child: TextField(
                            controller: creditController,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: isDark(context) ? Colors.white : Colors.black87),
                            decoration: fieldDecoration(context, hint: 'Credit', icon: Icons.school_outlined),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) => ref.read(totalCreditProvider.notifier).state = value,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: RoundedField(
                        child: ArrowTooltip(
                          key: gradeKey,
                          message: "Enter valid GPA",
                          child: TextField(
                            controller: gpaController,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: isDark(context) ? Colors.white : Colors.black87),
                            decoration: fieldDecoration(context, hint: 'GPA (4.0)', icon: Icons.star_border_rounded),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) => ref.read(totalGpaProvider.notifier).state = value,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, child) {
                          return Container(
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final creditStr = ref.read(totalCreditProvider);
                                  final gpaStr = ref.read(totalGpaProvider);
                                  final sem = ref.read(semesterProvider) ?? "N/A";
                                  final credit = double.tryParse(creditStr);
                                  final gpa = double.tryParse(gpaStr);
                                  bool hasError = false;
                                  
                                  if (credit == null || creditStr.trim().isEmpty) {
                                    showTooltip(creditKey);
                                    hasError = true;
                                  }
                                  if (gpaStr.trim().isEmpty || gpa == null || gpa > 4.0) {
                                    showTooltip(gradeKey);
                                    hasError = true;
                                  }
                                  if (hasError) return;
                                  
                                  final current = ref.read(SemesterListProvider);
                                  ref.read(SemesterListProvider.notifier).state = [
                                    ...current,
                                    {'credit': credit, 'gpa': gpa, 'semester': sem},
                                  ];
                                  
                                  ref.read(totalCreditProvider.notifier).state = '';
                                  ref.read(totalGpaProvider.notifier).state = '';
                                  ref.read(semesterProvider.notifier).state = null;
                                  creditController.clear();
                                  gpaController.clear();
                                },
                                child: Center(
                                  child: Text(
                                    "Add",
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                const Expanded(
                  child: SemesterListView(),
                ),
                
                const CgpaResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SemesterListView extends ConsumerWidget {
  const SemesterListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(SemesterListProvider);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              "No semesters added yet",
              style: GoogleFonts.inter(color: isDark(context) ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
      );
    }
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final semester = list[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester['semester'] ?? "Unnamed Semester",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark(context) ? Colors.white : primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark(context) ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("Credit: ${semester['credit']}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark(context) ? Colors.white70 : Colors.black87)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("GPA: ${semester['gpa']}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryColor)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final updated = [...ref.read(SemesterListProvider)]..remove(semester);
                  ref.read(SemesterListProvider.notifier).state = updated;
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2);
      },
    );
  }
}

class CgpaResult extends ConsumerWidget {
  const CgpaResult({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpa = ref.watch(cgpaProvider);
    final list = ref.watch(SemesterListProvider);
    
    if (list.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      padding: const EdgeInsets.all(20),
      borderColor: primaryColor.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Overall CGPA",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark(context) ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            cgpa.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark(context) ? Colors.white : primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5);
  }
}
