import 'package:eduvian/screen/cgpa.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:eduvian/screen/home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/credit.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/credit',
        builder: (context, state) => const CreditCalculation(),
      ),
      GoRoute(
        path: '/cgpa',
        builder: (context, state) => const CgpaCalculation(),
      ),
      GoRoute(
        path: '/gpa',
        builder: (context, state) => const GpaCalculation(),
      ),
    ],
  );
});
