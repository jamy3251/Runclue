import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/routine_service.dart';
import 'auth_provider.dart';

final routineServiceProvider = Provider<RoutineService>((ref) => RoutineService());

final myRoutinesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final svc = ref.read(routineServiceProvider);
  return svc.listMyRoutines(userId);
});
