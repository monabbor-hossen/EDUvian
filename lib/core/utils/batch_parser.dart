class StudentBatchModel {
  final int semester;
  final int? section;
  final String shift;
  final String departmentName;

  StudentBatchModel({
    required this.semester,
    this.section,
    required this.shift,
    required this.departmentName,
  });

  @override
  String toString() {
    return 'StudentBatchModel(semester: $semester, section: $section, shift: $shift, departmentName: $departmentName)';
  }
}

class BatchParser {
  /// Parses the batch string and email to construct a StudentBatchModel.
  /// 
  /// [email] should be the user's authenticated Google Workspace email.
  /// [batchString] is the raw string from the UI (e.g., "7DCSE.2").
  static StudentBatchModel parse({
    required String email,
    required String batchString,
  }) {
    // 0. Validate that this is a university email
    if (!email.toLowerCase().trim().endsWith('@eastdelta.edu.bd')) {
      throw FormatException(
        'Only East Delta University emails (@eastdelta.edu.bd) are supported. '
        'Please use your university email address.',
      );
    }

    // 1. Extract semester, shift letter, department, and section from batch string
    // Matches patterns like "7DCSE.2" or "12ECSE"
    // Group 1: Semester digits
    // Group 2: Shift letter (e.g. D or E)
    // Group 3: Department letters (e.g. CSE)
    // Group 4: Section digits (optional, after the dot)
    final regex = RegExp(r'^(\d+)([a-zA-Z])([a-zA-Z]+)(?:\.(\d+))?$');
    final match = regex.firstMatch(batchString.trim());

    if (match == null) {
      throw FormatException('Invalid batch string format. Expected format like "7DCSE.2", got: $batchString');
    }

    final semester = int.parse(match.group(1)!);
    final shiftLetter = match.group(2)!.toUpperCase();
    final deptLetters = match.group(3)!.toUpperCase();
    
    int? section;
    if (match.group(4) != null) {
      section = int.parse(match.group(4)!);
    }

    // 2. Determine Shift
    final isEvening = shiftLetter == 'E';
    final shift = isEvening ? 'Evening' : 'Regular';

    // 3. Determine Department string for saving
    final prefix = isEvening ? 'EBSC in' : 'BSC in';
    final departmentName = '$prefix $deptLetters';

    return StudentBatchModel(
      semester: semester,
      section: section,
      shift: shift,
      departmentName: departmentName,
    );
  }
}
