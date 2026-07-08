import 'package:eduvian/core/auth_service.dart';
import 'package:eduvian/screen/cgpa.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:eduvian/screen/home.dart';
import 'package:eduvian/screen/dashboard.dart';
import 'package:eduvian/screen/login.dart';
import 'package:eduvian/screen/main_layout.dart';
import 'package:eduvian/screen/messages.dart';
import 'package:eduvian/screen/routine.dart';
import 'package:eduvian/screen/settings.dart';
import 'package:eduvian/screen/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/credit.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final User? user = authState.asData?.value;
      final bool isLoggedIn = user != null;
      final bool goingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (isLoggedIn && goingToAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayoutScreen(navigationShell: navigationShell),
        branches: [
          // 0 — Dashboard
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          ]),
          // 1 — Routine
          StatefulShellBranch(routes: [
            GoRoute(path: '/routine', builder: (_, __) => const RoutineManagerScreen()),
          ]),
          // 2 — Messages (center FAB)
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
          ]),
          // 3 — Calculator
          StatefulShellBranch(routes: [
            GoRoute(path: '/calculator', builder: (_, __) => const HomeScreen()),
          ]),
          // 4 — Settings
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),

      // Standalone routes
      GoRoute(path: '/credit',  builder: (_, __) => const CreditCalculation()),
      GoRoute(path: '/cgpa',    builder: (_, __) => const CgpaCalculation()),
      GoRoute(path: '/gpa',     builder: (_, __) => const GpaCalculation()),
    ],
  );
});
