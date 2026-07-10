import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../dashboard/presentation/screens/main_layout_screen.dart' show checkedUids;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_background.dart';
import '../providers/auth_providers.dart';

// ─── Local State Providers ────────────────────────────────────────────────────
final _signupEmailProvider = StateProvider<String>((ref) => '');
final _signupPasswordProvider = StateProvider<String>((ref) => '');
final _signupConfirmPasswordProvider = StateProvider<String>((ref) => '');
final _signupPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final _signupConfirmVisibleProvider = StateProvider<bool>((ref) => false);
final _signupLoadingProvider = StateProvider<bool>((ref) => false);
final _signupErrorProvider = StateProvider<String?>((ref) => null);

// ─── Signup Screen ────────────────────────────────────────────────────────────
class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);
    final dark = isDark(context);

    final passVisible = ref.watch(_signupPasswordVisibleProvider);
    final confirmVisible = ref.watch(_signupConfirmVisibleProvider);
    final isLoading = ref.watch(_signupLoadingProvider);
    final errorMsg = ref.watch(_signupErrorProvider);

    final emailCtrl =
        TextEditingController(text: ref.read(_signupEmailProvider));
    final passCtrl =
        TextEditingController(text: ref.read(_signupPasswordProvider));
    final confirmCtrl =
        TextEditingController(text: ref.read(_signupConfirmPasswordProvider));

    Future<void> handleSignup() async {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text;
      final confirm = confirmCtrl.text;

      if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
        ref.read(_signupErrorProvider.notifier).state =
            'Please fill in all fields.';
        return;
      }
      if (pass != confirm) {
        ref.read(_signupErrorProvider.notifier).state =
            'Passwords do not match.';
        return;
      }
      if (pass.length < 6) {
        ref.read(_signupErrorProvider.notifier).state =
            'Password must be at least 6 characters.';
        return;
      }

      ref.read(_signupLoadingProvider.notifier).state = true;
      ref.read(_signupErrorProvider.notifier).state = null;

      try {
        final result = await ref.read(authServiceProvider).signUpWithEmail(email, pass);
        // Brand-new email signup — clear any stale academic_info so the
        // onboarding dialog will show when MainLayoutScreen mounts.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('academic_info');
        checkedUids.remove(result.user?.uid);
        if (context.mounted) context.go('/');
      } on FirebaseAuthException catch (e) {
        ref.read(_signupErrorProvider.notifier).state =
            e.message ?? 'Registration failed.';
      } finally {
        ref.read(_signupLoadingProvider.notifier).state = false;
      }
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E1E24) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: dark ? Border.all(color: Colors.white12) : null,
                  boxShadow: [
                    BoxShadow(
                      color: dark ? Colors.black54 : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──────────────────────────────────────────────────
                    Center(
                      child: Image.asset(
                        'assets/icon/EDUvian-Icon.png',
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Title ─────────────────────────────────────────────────
                    const Center(
                      child: Text(
                        'EDUvian',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Create your academic account',
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.white60 : const Color(0xFF888888),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Email ─────────────────────────────────────────────────
                    _fieldLabel('INSTITUTIONAL EMAIL'),
                    const SizedBox(height: 8),
                    _AuthTextField(
                      controller: emailCtrl,
                      hintText: 'student@university.edu',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) =>
                          ref.read(_signupEmailProvider.notifier).state = v,
                    ),
                    const SizedBox(height: 20),

                    // ── Password ──────────────────────────────────────────────
                    _fieldLabel('PASSWORD'),
                    const SizedBox(height: 8),
                    _AuthTextField(
                      controller: passCtrl,
                      hintText: '••••••••',
                      obscureText: !passVisible,
                      onChanged: (v) =>
                          ref.read(_signupPasswordProvider.notifier).state = v,
                      suffixIcon: GestureDetector(
                        onTap: () => ref
                            .read(_signupPasswordVisibleProvider.notifier)
                            .state = !passVisible,
                        child: Icon(
                          passVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFAAAAAA),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Confirm Password ──────────────────────────────────────
                    _fieldLabel('CONFIRM PASSWORD'),
                    const SizedBox(height: 8),
                    _AuthTextField(
                      controller: confirmCtrl,
                      hintText: '••••••••',
                      obscureText: !confirmVisible,
                      onChanged: (v) => ref
                          .read(_signupConfirmPasswordProvider.notifier)
                          .state = v,
                      suffixIcon: GestureDetector(
                        onTap: () => ref
                            .read(_signupConfirmVisibleProvider.notifier)
                            .state = !confirmVisible,
                        child: Icon(
                          confirmVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFAAAAAA),
                          size: 20,
                        ),
                      ),
                    ),

                    // ── Error ─────────────────────────────────────────────────
                    if (errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          errorMsg,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Register Button ───────────────────────────────────────
                    _RegisterButton(
                      isLoading: isLoading,
                      onPressed: handleSignup,
                    ),
                    const SizedBox(height: 24),

                    // ── Back to login ─────────────────────────────────────────
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                                color: dark ? Colors.white70 : const Color(0xFF555555), fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────--------------------------------------------------
Widget _fieldLabel(String text) {
  return Builder(
    builder: (context) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark(context) ? Colors.white70 : const Color(0xFF444444),
          letterSpacing: 1.0,
        ),
      );
    }
  );
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2C2C32) : const Color(0xFFF7F4F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white12 : const Color(0xFFE8E0EE), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(fontSize: 15, color: dark ? Colors.white : const Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              TextStyle(color: dark ? Colors.white38 : const Color(0xFFBBBBBB), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
