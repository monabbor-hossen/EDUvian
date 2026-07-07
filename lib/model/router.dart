import 'package:eduvian/core/auth_service.dart';
import 'package:eduvian/screen/cgpa.dart';
import 'package:eduvian/screen/gpa.dart';
import 'package:eduvian/screen/home.dart';
import 'package:eduvian/screen/login.dart';
import 'package:eduvian/screen/settings.dart';
import 'package:eduvian/screen/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screen/credit.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so the router refreshes when the user logs in/out.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final User? user = authState.asData?.value;
      final bool isLoggedIn = user != null;
      final bool goingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If already logged in, no need to visit login/signup screens
      if (isLoggedIn && goingToAuth) return '/';
      // All other routes are publicly accessible — no forced login
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
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

