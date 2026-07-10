import '../../domain/entities/class_entry.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_remote_datasource.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDataSource _remoteDataSource;

  RoutineRepositoryImpl({required RoutineRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<void> addClass(String day, ClassEntry entry) {
    return _remoteDataSource.addClass(day, entry);
  }

  @override
  Future<void> updateClass(String day, ClassEntry entry, {String? notificationHint}) {
    return _remoteDataSource.updateClass(day, entry, notificationHint: notificationHint);
  }

  @override
  Future<void> deleteClass(String day, String classId) {
    return _remoteDataSource.deleteClass(day, classId);
  }

  @override
  Stream<Map<String, List<ClassEntry>>> streamRoutine(String batchId) {
    return _remoteDataSource.streamRoutine(batchId).map((map) {
      return map.map((key, value) => MapEntry(key, value.cast<ClassEntry>()));
    });
  }
}
