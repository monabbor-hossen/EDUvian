import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/calculator/presentation/screens/calculator_home_screen.dart';
import '../../features/calculator/presentation/screens/cgpa_screen.dart';
import '../../features/calculator/presentation/screens/credit_screen.dart';
import '../../features/calculator/presentation/screens/gpa_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/main_layout_screen.dart';
import '../../features/chat/presentation/screens/create_group_members_screen.dart';
import '../../features/chat/presentation/screens/create_group_name_screen.dart';
import '../../features/chat/presentation/screens/messages_screen.dart';
import '../../features/chat/presentation/screens/new_chat_screen.dart';
import '../../features/routine/presentation/screens/routine_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

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
            GoRoute(
              path: '/messages',
              builder: (_, __) => const MessagesScreen(),
              routes: [
                GoRoute(
                  path: 'room/:sectionId',
                  pageBuilder: (context, state) {
                    final sectionId = state.pathParameters['sectionId'] ?? '';
                    return CustomTransitionPage(
                      child: ChatRoomScreen(sectionId: sectionId),
                      transitionsBuilder: (_, anim, __, child) =>
                          SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'new-chat',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const NewChatScreen(),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                ),
                GoRoute(
                  path: 'create-group-members',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const CreateGroupMembersScreen(),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                ),
                GoRoute(
                  path: 'create-group-name',
                  pageBuilder: (context, state) {
                    final selectedUsers = state.extra as List<Map<String, dynamic>>? ?? [];
                    return CustomTransitionPage(
                      child: CreateGroupNameScreen(selectedUsers: selectedUsers),
                      transitionsBuilder: (_, anim, __, child) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    );
                  },
                ),
              ],
            ),
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
