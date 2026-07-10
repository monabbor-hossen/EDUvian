import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subject.dart';

// General providers
final departmentProvider = StateProvider<String?>((ref) => null);
final subjectProvider = StateProvider<List<Subject>>((ref) => []);

// GPA calculation providers
final gradeProvider = StateProvider<Map<String, String>>((ref) => {});

// CGPA calculation providers
final totalCreditProvider = StateProvider<String>((ref) => '');
final totalGpaProvider = StateProvider<String>((ref) => '');
final SemesterListProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Credit / Cost calculation providers
final scholoarshipProvider = StateProvider<String>((ref) => 'Default');
final discountProvider = StateProvider<bool>((ref) => false);
final semesterProvider = StateProvider<String?>((ref) => null);

// GPA / CGPA compute providers
final gpaProvider = Provider<double>((ref) {
  final subjects = ref.watch(subjectProvider);
  final grades = ref.watch(gradeProvider);

  double totalPoints = 0;
  double totalCredits = 0;
  for (var subject in subjects) {
    final grade = grades[subject.Code];
    final credit = subject.Credit;
    if (grade != null && gradeToPoint.containsKey(grade)) {
      final point = gradeToPoint[grade]!;
      totalPoints += point * credit;
      totalCredits += credit;
    }
  }
  return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
});

final cgpaProvider = Provider<double>((ref) {
  final semesters = ref.watch(SemesterListProvider);
  double totalCredit = 0;
  double totalWeightedGPA = 0;

  for (var semester in semesters) {
    final credit = semester['credit'] as double;
    final gpa = semester['gpa'] as double;

    totalCredit += credit;
    totalWeightedGPA += gpa * credit;
  }
  if (totalCredit == 0) return 0;
  return totalWeightedGPA / totalCredit;
});

// Grade mappings
final Map<String, double> gradeToPoint = {
  'A+': 4.0,
  'A': 3.75,
  'A-': 3.5,
  'B+': 3.25,
  'B': 3.0,
  'B-': 2.75,
  'C+': 2.5,
  'C': 2.25,
  'D': 2.0,
  'F': 0.0,
};

final List<String> semester = [
  '1st Year 1st Semester',
  '1st Year 2nd Semester',
  '2nd Year 1st Semester',
  '2nd Year 2nd Semester',
  '3rd Year 1st Semester',
  '3rd Year 2nd Semester',
  '4th Year 1st Semester',
  '4th Year 2nd Semester',
];
