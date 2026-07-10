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
    // 1. Determine shift & department from email
    final localPart = email.split('@').first.trim().toLowerCase();
    
    // Check if the local part ends with an 'e' (Evening shift)
    final isEvening = localPart.endsWith('e');
    
    final shift = isEvening ? 'Evening' : 'Regular';
    final departmentName = isEvening ? 'EBSC in CSE' : 'BSC in CSE';

    // 2. Extract semester and section from batch string
    // Matches patterns like "7DCSE.2" or "12DCSE"
    // Group 1: Semester digits
    // Group 2: Section digits (optional, after the dot)
    final regex = RegExp(r'^(\d+)[a-zA-Z]+(?:\.(\d+))?$');
    final match = regex.firstMatch(batchString.trim());

    if (match == null) {
      throw FormatException('Invalid batch string format. Expected format like "7DCSE.2", got: $batchString');
    }

    final semester = int.parse(match.group(1)!);
    int? section;
    if (match.group(2) != null) {
      section = int.parse(match.group(2)!);
    }

    return StudentBatchModel(
      semester: semester,
      section: section,
      shift: shift,
      departmentName: departmentName,
    );
  }
}
