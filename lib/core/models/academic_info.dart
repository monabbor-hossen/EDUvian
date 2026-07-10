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
