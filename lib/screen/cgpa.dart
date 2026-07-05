import 'package:eduvian/model/ArrowTooltip.dart';
import 'package:eduvian/model/department.dart';
import 'package:eduvian/model/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final totalCreditProvider = StateProvider<String>((ref) => '');
final totalGpaProvider = StateProvider<String>((ref) => '');
final SemesterListProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final cgpaProvider = Provider<double>((ref) {
  final semesters = ref.watch(SemesterListProvider);
  double totalCredit = 0;
  double totalWetghtedGPA = 0;

  for (var semester in semesters) {
    final credit = semester['credit'] as double;
    final gpa = semester['gpa'] as double;

    totalCredit += credit;
    totalWetghtedGPA += gpa * credit;
  }
  if (totalCredit == 0) return 0;
  return totalWetghtedGPA / totalCredit;
});

class CgpaCalculation extends ConsumerStatefulWidget {
  const CgpaCalculation({super.key});

  @override
  ConsumerState<CgpaCalculation> createState() => _CgpaCalculationState();
}

class _CgpaCalculationState extends ConsumerState<CgpaCalculation> {
  final creditController = TextEditingController();
  final gpaController = TextEditingController();

  @override
  void dispose() {
    creditController.dispose();
    gpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context, "CGPA"),
      body: Container(
        padding: EdgeInsets.all(16),
        color: offWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                return RoundedField(
                  child: DropdownButtonFormField<String>(
                    initialValue: ref.watch(departmentProvider),
                    decoration: const InputDecoration(
                      hintText: "Department",
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    dropdownColor: offWhite,
                    items:
                        department.keys
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      ref.read(departmentProvider.notifier).state = value;
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            Consumer(
              builder: (context, ref, child) {
                return RoundedField(
                  child: DropdownButtonFormField(
                    initialValue: ref.watch(semesterProvider),
                    decoration: const InputDecoration(
                      hintText: "semester",
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    dropdownColor: offWhite,
                    items:
                        semester
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      ref.read(semesterProvider.notifier).state = value;
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  flex: 3,
                  child: Consumer(
                    builder: (context, ref, child) {
                      return RoundedField(
                        child: GestureDetector(
                          onTap: () {},
                          child: ArrowTooltip(
                            key: creditKey,
                            message: "Please enter your Credit",
                            child: TextField(
                              controller: creditController,
                              decoration: const InputDecoration(
                                hintText: 'Total Credit',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),

                              keyboardType: TextInputType.number,
                              onChanged:
                                  (value) =>
                                      ref
                                          .read(totalCreditProvider.notifier)
                                          .state = value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Consumer(
                    builder: (context, ref, child) {
                      return RoundedField(
                        child: GestureDetector(
                          onTap: () {},
                          child: ArrowTooltip(
                            key: gradeKey,
                            message: "Please enter your GPA",
                            child: TextField(
                              controller: gpaController,
                              decoration: const InputDecoration(
                                hintText: 'GPA (max 4.0)',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged:
                                  (value) =>
                                      ref
                                          .read(totalGpaProvider.notifier)
                                          .state = value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: offWhite,
                          padding: EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          final creditStr = ref.read(totalCreditProvider);
                          final gpaStr = ref.read(totalGpaProvider);
                          final semester = ref.read(semesterProvider);
                          final credit = double.tryParse(creditStr);
                          final gpa = double.tryParse(gpaStr);
                          bool hasError = false;
                          if (credit == null || creditStr.trim().isEmpty) {
                            showTooltip(creditKey);
                            hasError = true;
                          }
                          if (gpaStr.trim().isEmpty ||
                              gpa == null ||
                              gpa > 4.0) {
                            showTooltip(gradeKey);
                            hasError = true;
                          }
                          if (hasError) return;
                          final current = ref.read(SemesterListProvider);
                          ref.read(SemesterListProvider.notifier).state = [
                            ...current,
                            {
                              'credit': credit,
                              'gpa': gpa,
                              'semester': semester,
                            },
                          ];
                          ref.read(totalCreditProvider.notifier).state = '';
                          ref.read(totalGpaProvider.notifier).state = '';
                          ref.read(semesterProvider.notifier).state = null;
                          creditController.clear();
                          gpaController.clear();
                        },
                        child: const Text("Add"),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SemesterListView(),
            const CgpaResult(),
          ],
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
      return const Text("No semester added yet.");
    }
    return Consumer(
      builder: (contex, ref, child) {
        return Expanded(
          child: SizedBox(
            height: (list.length > 5 ? 5 : list.length) * 70,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final semester = list[index];
                return Card(
                  color: offWhite,
                  child: ListTile(
                    visualDensity: VisualDensity(vertical: -2),
                    title: Text(semester['semester'] ?? "Unnamed Semester"),
                    subtitle: Text(
                      "Credit: ${semester['credit']} | GPA: ${semester['gpa']}",
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        final updated = [...ref.read(SemesterListProvider)]
                          ..remove(semester);
                        ref.read(SemesterListProvider.notifier).state = updated;
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class CgpaResult extends ConsumerWidget {
  const CgpaResult({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpa = ref.watch(cgpaProvider);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade100.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Your CGPA: ${cgpa.toStringAsFixed(2)}",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }
}
