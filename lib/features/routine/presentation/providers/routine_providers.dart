import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/models/academic_info.dart';
import '../../data/datasources/routine_remote_datasource.dart';
import '../../data/repositories/routine_repository_impl.dart';
import '../../domain/entities/class_entry.dart';
import '../../domain/repositories/routine_repository.dart';

final routineRemoteDataSourceProvider = Provider<RoutineRemoteDataSource>((ref) {
  return RoutineRemoteDataSourceImpl();
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final remoteDataSource = ref.watch(routineRemoteDataSourceProvider);
  return RoutineRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Legacy compat alias
final routineServiceProvider = Provider<RoutineRepository>((ref) {
  return ref.watch(routineRepositoryProvider);
});

/// Reads academic_info from SharedPreferences once.
final academicInfoProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('academic_info') ?? '';
});

String? batchIdFromRaw(String raw) {
  final info = parseAcademicInfo(raw);
  if (info == null) return null;
  final base = '${info.semester}${info.department}';
  return info.section != null ? '${base}_${info.section}' : base;
}

/// Firestore document ID derived from the current academic_info.
final batchIdProvider = Provider<String?>((ref) {
  return ref.watch(academicInfoProvider).when(
    data: batchIdFromRaw,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Live stream of the full routine for the current batch.
final routineProvider = StreamProvider<Map<String, List<ClassEntry>>>((ref) {
  final infoAsync = ref.watch(academicInfoProvider);

  return infoAsync.when(
    loading: () => Stream.value({}),
    error: (_, __) => Stream.value({}),
    data: (raw) {
      final batchId = batchIdFromRaw(raw);
      if (batchId == null || batchId.isEmpty) return Stream.value({});

      final repository = ref.watch(routineRepositoryProvider);
      return repository.streamRoutine(batchId);
    },
  );
});
