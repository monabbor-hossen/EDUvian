import '../../domain/entities/class_entry.dart';

abstract class RoutineRepository {
  Future<void> addClass(String day, ClassEntry entry);
  Future<void> updateClass(String day, ClassEntry entry, {String? notificationHint});
  Future<void> deleteClass(String day, String classId);
  Stream<Map<String, List<ClassEntry>>> streamRoutine(String batchId);
}
