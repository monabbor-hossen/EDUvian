import 'package:eduvian/model/ArrowTooltip.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'department.dart';

class RoundedField extends StatelessWidget {
  final Widget child;
  const RoundedField({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: offWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.25),
            offset: Offset(0.1, 0.2),
            blurRadius: 4,
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

InputDecoration inputDecoration() => InputDecoration(
  filled: true,
  fillColor: offWhite,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class DropdownField extends ConsumerWidget {
  final StateProvider<String?> ProviderName;
  final List<String> item;
  final String? hintText;
  final void Function(WidgetRef ref, String?)? onChangeExtra;
  const DropdownField({
    Key? key,
    required this.ProviderName,
    required this.item,
    this.hintText,
    this.onChangeExtra,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectValue = ref.watch(ProviderName);
    return DropdownButtonFormField<String>(
      initialValue: selectValue,
      decoration: inputDecoration(),
      dropdownColor: offWhite,
      icon: Icon(Icons.keyboard_arrow_down_rounded),
      iconEnabledColor: Colors.black,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      borderRadius: BorderRadius.circular(8),
      items: [
        if (hintText != null)
          DropdownMenuItem<String>(value: null, child: Text(hintText!)),

        ...item.map((value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
      ],
      onChanged: (newValue) {
        ref.read(ProviderName.notifier).state = newValue!;
        if (onChangeExtra != null) {
          onChangeExtra!(ref, newValue);
        }
      },
    );
  }
}

InputDecoration fieldDecoration({String? hint, IconData? icon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      prefixIcon: icon != null ? Icon(icon, color: Colors.black54) : null,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class SubjectAutoComplete extends ConsumerWidget {
  final StateProvider<String?> departmentProvider;
  final Map<String?, List<Subject>> departmentMap;
  final StateProvider<List<Subject>> subjectProvider;
  final InputDecoration Function({required String hint, required IconData icon})
  fieldDecoration;
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
              subject.Code.toLowerCase().contains(
                subjectName.text.toLowerCase(),
              ) ||
              subject.Title.toLowerCase().contains(
                subjectName.text.toLowerCase(),
              ),
        );
      },
      displayStringForOption:
          (Subject option) => '${option.Code} ${option.Title}',

      fieldViewBuilder: (context, controller, focuseNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focuseNode,
          onTap: () {
            controller.clear(); // clear directly
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          },
          onEditingComplete: onEditingComplete,
          decoration: fieldDecoration(
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
            elevation: 4.0,
            borderRadius: BorderRadius.circular(10),
            color: offWhite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: ((options.length * 50.0).clamp(0, 5 * 50.0)),
                maxWidth: (MediaQuery.of(context).size.width) * 0.965,
              ),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 4),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      option.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => onSelected(option),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusColor: Colors.teal.shade100.withValues(alpha: 0.3),
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

const primaryColor = Color.fromRGBO(107, 0, 50, 1);
const offWhite = Color.fromRGBO(255, 249, 242, 1);
AppBar appBar(BuildContext context, String title) => AppBar(
  backgroundColor: primaryColor,
  elevation: 0,
  title: Text(
    "${title}",
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
  leading:
      GoRouter.of(context).canPop()
          ? IconButton(
            onPressed: () {
              context.pop();
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          )
          : null,
  centerTitle: true,
);

final gradeToPoint = {
  'A': 4.0,
  'A-': 3.7,
  'B+': 3.3,
  'B': 3.0,
  'B-': 2.7,
  'C+': 2.3,
  'C': 2.0,
  'C-': 1.7,
  'D+': 1.3,
  'D': 1.0,
  'F': 0.0,
};
final semester = {
  "Semester 1",
  "Semester 2",
  "Semester 3",
  "Semester 4",
  "Semester 5",
  "Semester 6",
  "Semester 7",
  "Semester 8",
  "Semester 9",
  "Semester 10",
  "Semester 11",
  "Semester 12",
};
final creditTo = [
  "1",
  "1.5",
  "2",
  "2.5",
  "3",
  "3.5",
  "4",
  "4.5",
  "5",
  "5.5",
  "6",
];
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
      return AlertDialog(
        backgroundColor: offWhite,
        title: const Text('Add Credit'),
        content: Consumer(
          builder: (context, ref, child) {
            final selectGrade = ref.watch(dialogCreditProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RoundedField(
                  child: GestureDetector(
                    onTap: () {},

                    child: ArrowTooltip(
                      key: creditKey,
                      arrowPosition: 'topCenter',
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      message: "Please select a Credit",
                      child: DropdownButtonFormField<String>(
                        initialValue: selectGrade.isNotEmpty ? selectGrade : null,
                        decoration: const InputDecoration(
                          hintText: "Credit",
                          contentPadding: EdgeInsets.all(8),
                          border: InputBorder.none,
                        ),
                        dropdownColor: offWhite,
                        items:
                            creditTo
                                .map(
                                  (credit) => DropdownMenuItem(
                                    value: credit,
                                    child: Text(credit),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            ref.read(dialogCreditProvider.notifier).state =
                                value;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                RoundedField(
                  child: GestureDetector(
                    onTap: () {},
                    child: ArrowTooltip(
                      key: gradeKey,
                      arrowPosition: 'bottomCenter',
                      message: "Please select a grade",
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            gradeToPoint.keys.contains(selectGrade)
                                ? selectGrade
                                : null,
                        decoration: const InputDecoration(
                          hintText: "Grade",
                          contentPadding: EdgeInsets.all(8),
                          border: InputBorder.none,
                        ),
                        dropdownColor: offWhite,
                        items:
                            gradeToPoint.keys
                                .map(
                                  (grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ),
                                )
                                .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            ref.read(dialogGradeProvider.notifier).state =
                                value;
                          }
                        },
                      ),
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
            child: const Text('Cancel', style: TextStyle(color: primaryColor)),
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
                final newSubject = Subject(
                  "Manual-${currentSubjects.length + 1}",
                  "Custom Subject",
                  credit!,
                );
                ref.read(subjectProvider.notifier).state = [
                  ...currentSubjects,
                  newSubject,
                ];

                final currentGrades = ref.read(gradeProvider);

                ref.read(gradeProvider.notifier).state = {
                  ...currentGrades,
                  newSubject.Code: grade!,
                };
                ref.read(dialogGradeProvider.notifier).state = null;
                ref.read(dialogCreditProvider.notifier).state = '';
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: offWhite,
            ),
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

final semesterProvider = StateProvider<String?>((ref) => null);
