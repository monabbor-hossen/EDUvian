import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets.dart';

// ═══════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════

/// Ordered list of days starting from Sunday (matching Dart weekday % 7 logic).
const List<String> kDays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/// Today's day name — Dart weekday: 1=Mon…7=Sun → index 0=Sun via mod.
String get todayName => kDays[DateTime.now().weekday % 7];

// ═══════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════

class ClassEntry {
  final String id;
  final String subject;
  final String startTime; // "HH:mm" 24-hour
  final String endTime; // "HH:mm" 24-hour
  final String room;
  final String teacher;

  const ClassEntry({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacher,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'teacher': teacher,
  };

  factory ClassEntry.fromMap(Map<String, dynamic> map) => ClassEntry(
    id: map['id'] as String? ?? '',
    subject: map['subject'] as String? ?? '',
    startTime: map['startTime'] as String? ?? '',
    endTime: map['endTime'] as String? ?? '',
    room: map['room'] as String? ?? '',
    teacher: map['teacher'] as String? ?? '',
  );

  ClassEntry copyWith({
    String? id,
    String? subject,
    String? startTime,
    String? endTime,
    String? room,
    String? teacher,
  }) => ClassEntry(
    id: id ?? this.id,
    subject: subject ?? this.subject,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    room: room ?? this.room,
    teacher: teacher ?? this.teacher,
  );

  /// True if current time falls within this class period.
  bool get isOngoing {
    final s = _toMinutes(startTime);
    final e = _toMinutes(endTime);
    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    return s != null && e != null && now >= s && now < e;
  }

  /// Minutes since midnight for sorting by start time.
  int get startMinutes => _toMinutes(startTime) ?? 0;

  static int? _toMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}

// ═══════════════════════════════════════════════════════════════════
// BATCH ID HELPER
// ═══════════════════════════════════════════════════════════════════

/// Derives Firestore document ID from the raw academic_info string.
/// "7DCSE.2" → "7CSE_2",  "7DCSE" → "7CSE"
String? batchIdFromRaw(String raw) {
  final info = parseAcademicInfo(raw);
  if (info == null) return null;
  final base = '${info.semester}${info.department}';
  return info.section != null ? '${base}_${info.section}' : base;
}

// ═══════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════

/// Reads academic_info from SharedPreferences once.
/// Call `ref.invalidate(academicInfoProvider)` after saving new info.
final academicInfoProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('academic_info') ?? '';
});

/// Firestore document ID derived from the current academic_info.
final batchIdProvider = Provider<String?>((ref) {
  return ref.watch(academicInfoProvider).when(
    data: batchIdFromRaw,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Live stream of the full routine for the current batch.
/// Returns `Map<dayName, List<ClassEntry>>` sorted by start time.
final routineProvider = StreamProvider<Map<String, List<ClassEntry>>>((ref) {
  final infoAsync = ref.watch(academicInfoProvider);

  return infoAsync.when(
    loading: () => Stream.value({}),
    error: (_, __) => Stream.value({}),
    data: (raw) {
      final batchId = batchIdFromRaw(raw);
      if (batchId == null || batchId.isEmpty) return Stream.value({});

      return FirebaseFirestore.instance
          .collection('routines')
          .doc(batchId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return {for (final d in kDays) d: <ClassEntry>[]};
        }
        final data = doc.data()!;
        final result = <String, List<ClassEntry>>{};
        for (final day in kDays) {
          final rawList = data[day];
          if (rawList is List) {
            result[day] = rawList
                .map((e) => ClassEntry.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList()
              ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
          } else {
            result[day] = [];
          }
        }
        return result;
      });
    },
  );
});

// ═══════════════════════════════════════════════════════════════════
// ROUTINE SERVICE  (CRUD — writes to Firestore)
// ═══════════════════════════════════════════════════════════════════

class RoutineService {
  final _db = FirebaseFirestore.instance;

  Future<String> _batchId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = batchIdFromRaw(prefs.getString('academic_info') ?? '');
    if (id == null || id.isEmpty) {
      throw Exception('Academic info not set. Please update it in Settings.');
    }
    return id;
  }

  DocumentReference<Map<String, dynamic>> _ref(String batchId) =>
      _db.collection('routines').doc(batchId);

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Adds a new class to [day]. Assigns a generated id automatically.
  Future<void> addClass(String day, ClassEntry entry) async {
    final id = await _batchId();
    final withId = entry.copyWith(id: _newId());
    await _ref(id).set(
      {day: FieldValue.arrayUnion([withId.toMap()])},
      SetOptions(merge: true),
    );
  }

  /// Replaces the class with the same id as [entry] within [day].
  Future<void> updateClass(String day, ClassEntry entry) async {
    final batchId = await _batchId();
    final ref = _ref(batchId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data() ?? {};
      final list = ((data[day] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = list.indexWhere((e) => e['id'] == entry.id);
      if (idx < 0) return;
      list[idx] = entry.toMap();
      txn.set(ref, {day: list}, SetOptions(merge: true));
    });
  }

  /// Removes the class with [classId] from [day].
  Future<void> deleteClass(String day, String classId) async {
    final batchId = await _batchId();
    final ref = _ref(batchId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data() ?? {};
      final list = ((data[day] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..removeWhere((e) => e['id'] == classId);
      txn.set(ref, {day: list}, SetOptions(merge: true));
    });
  }
}

final routineServiceProvider =
    Provider<RoutineService>((ref) => RoutineService());
