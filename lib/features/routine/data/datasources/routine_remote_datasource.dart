import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/academic_info.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/class_entry.dart';
import '../models/class_entry_model.dart';

const List<String> kDays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

abstract class RoutineRemoteDataSource {
  Future<void> addClass(String day, ClassEntry entry);
  Future<void> updateClass(String day, ClassEntry entry, {String? notificationHint});
  Future<void> deleteClass(String day, String classId);
  Stream<Map<String, List<ClassEntryModel>>> streamRoutine(String batchId);
}

class RoutineRemoteDataSourceImpl implements RoutineRemoteDataSource {
  final FirebaseFirestore _db;
  final NotificationService _notificationService;

  RoutineRemoteDataSourceImpl({
    FirebaseFirestore? db,
    NotificationService? notificationService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  Future<String> _batchId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('academic_info') ?? '';
    final info = parseAcademicInfo(raw);
    if (info == null) {
      throw Exception('Academic info not set. Please update it in Settings.');
    }
    
    // Read the shift we saved during setup
    final shift = prefs.getString('shift') ?? 'Regular';
    final prefix = shift == 'Evening' ? 'E_' : '';
    
    final base = '${prefix}${info.semester}${info.department}';
    return info.section != null ? '${base}_${info.section}' : base;
  }

  DocumentReference<Map<String, dynamic>> _ref(String batchId) =>
      _db.collection('routines').doc(batchId);

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<void> addClass(String day, ClassEntry entry) async {
    final batchId = await _batchId();
    final withId = ClassEntryModel(
      id: _newId(),
      subject: entry.subject,
      startTime: entry.startTime,
      endTime: entry.endTime,
      room: entry.room,
      teacher: entry.teacher,
      weekType: entry.weekType,
      dateEvents: entry.dateEvents,
    );

    await _ref(batchId).set(
      {day: FieldValue.arrayUnion([withId.toMap()])},
      SetOptions(merge: true),
    );

    // Notify classmates
    final prefs = await SharedPreferences.getInstance();
    final rawInfo = prefs.getString('academic_info');
    if (rawInfo != null && rawInfo.isNotEmpty) {
      final info = parseAcademicInfo(rawInfo);
      if (info != null) {
        final shift = prefs.getString('shift') ?? 'Regular';
        final prefix = shift == 'Evening' ? 'E_' : '';
        String topic = 'batch_$prefix${info.semester}_${info.department}';
        if (info.section != null) topic += '_${info.section}';

        await _notificationService.sendNotificationToTopic(
          title: "New Class Added",
          body: "${entry.subject} added to $day's routine.",
          topicName: topic,
        );
      }
    }
  }

  @override
  Future<void> updateClass(String day, ClassEntry entry, {String? notificationHint}) async {
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
      
      final entryModel = ClassEntryModel(
        id: entry.id,
        subject: entry.subject,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: entry.room,
        teacher: entry.teacher,
        weekType: entry.weekType,
        dateEvents: entry.dateEvents,
      );
      list[idx] = entryModel.toMap();
      txn.set(ref, {day: list}, SetOptions(merge: true));
    });

    // Notify classmates
    final prefs = await SharedPreferences.getInstance();
    final rawInfo = prefs.getString('academic_info');
    if (rawInfo != null && rawInfo.isNotEmpty) {
      final info = parseAcademicInfo(rawInfo);
      if (info != null) {
        final shift = prefs.getString('shift') ?? 'Regular';
        final prefix = shift == 'Evening' ? 'E_' : '';
        String topic = 'batch_$prefix${info.semester}_${info.department}';
        if (info.section != null) topic += '_${info.section}';

        final body = notificationHint ?? "${entry.subject} on $day has been updated.";
        _notificationService.sendNotificationToTopic(
          title: "📢 Routine Updated",
          body: body,
          topicName: topic,
        );
      }
    }
  }

  @override
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

    // Notify classmates
    final prefs = await SharedPreferences.getInstance();
    final rawInfo = prefs.getString('academic_info');
    if (rawInfo != null && rawInfo.isNotEmpty) {
      final info = parseAcademicInfo(rawInfo);
      if (info != null) {
        final shift = prefs.getString('shift') ?? 'Regular';
        final prefix = shift == 'Evening' ? 'E_' : '';
        String topic = 'batch_$prefix${info.semester}_${info.department}';
        if (info.section != null) topic += '_${info.section}';

        _notificationService.sendNotificationToTopic(
          title: "Routine Updated",
          body: "A class on $day was removed from the routine.",
          topicName: topic,
        );
      }
    }
  }

  @override
  Stream<Map<String, List<ClassEntryModel>>> streamRoutine(String batchId) {
    if (batchId.isEmpty) return Stream.value({});

    return _ref(batchId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return {for (final d in kDays) d: <ClassEntryModel>[]};
      }
      final data = doc.data()!;
      final result = <String, List<ClassEntryModel>>{};
      for (final day in kDays) {
        final rawList = data[day];
        if (rawList is List) {
          result[day] = rawList
              .map((e) => ClassEntryModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
            ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        } else {
          result[day] = [];
        }
      }
      return result;
    });
  }
}
