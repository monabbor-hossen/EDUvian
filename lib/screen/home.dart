import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_service.dart';
import '../model/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'EDUvian',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isLoggedIn)
            // ── Avatar + popup menu when logged in ────────────────────────
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 28,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              itemBuilder: (_) => [
                // User info header (non-interactive)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName!
                            : 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                        ),
                      ),
                      const Divider(height: 16),
                    ],
                  ),
                ),
                // Logout item
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            // ── Login button when not logged in ───────────────────────────
            TextButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login, color: Colors.white, size: 20),
              label: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Center(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'Credit & Cost Calculator',
                    color: primaryColor,
                    onTap: '/credit',
                  ),
                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'GPA Calculator',
                    color: primaryColor,
                    onTap: '/gpa',
                  ),
                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'CGPA Calculator',
                    color: primaryColor,
                    onTap: '/cgpa',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String onTap,
  }) {
    return GestureDetector(
      onTap: () => context.push(onTap),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
