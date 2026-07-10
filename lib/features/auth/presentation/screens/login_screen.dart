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
final _loginEmailProvider = StateProvider<String>((ref) => '');
final _loginPasswordProvider = StateProvider<String>((ref) => '');
final _passwordVisibleProvider = StateProvider<bool>((ref) => false);
final _isLoadingProvider = StateProvider<bool>((ref) => false);
final _loginErrorProvider = StateProvider<String?>((ref) => null);

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color.fromRGBO(107, 0, 50, 1);
    final dark = isDark(context);

    final passwordVisible = ref.watch(_passwordVisibleProvider);
    final isLoading = ref.watch(_isLoadingProvider);
    final errorMsg = ref.watch(_loginErrorProvider);

    final emailCtrl = TextEditingController(text: ref.read(_loginEmailProvider));
    final passCtrl = TextEditingController(text: ref.read(_loginPasswordProvider));

    Future<void> handleEmailLogin() async {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text;

      if (email.isEmpty || pass.isEmpty) {
        ref.read(_loginErrorProvider.notifier).state =
            'Please fill in all fields.';
        return;
      }

      ref.read(_isLoadingProvider.notifier).state = true;
      ref.read(_loginErrorProvider.notifier).state = null;

      try {
        await ref.read(authServiceProvider).signInWithEmail(email, pass);
        if (context.mounted) context.go('/');
      } on FirebaseAuthException catch (e) {
        ref.read(_loginErrorProvider.notifier).state =
            e.message ?? 'Login failed. Please try again.';
      } catch (e) {
        ref.read(_loginErrorProvider.notifier).state =
            e.toString().replaceAll('Exception: ', '');
      } finally {
        ref.read(_isLoadingProvider.notifier).state = false;
      }
    }

    Future<void> handleGoogleLogin() async {
      ref.read(_isLoadingProvider.notifier).state = true;
      ref.read(_loginErrorProvider.notifier).state = null;
      try {
        final result =
            await ref.read(authServiceProvider).signInWithGoogle();
        if (result != null && context.mounted) {
          // If this is a brand-new Google account, clear any stale academic_info
          // so the onboarding dialog always shows for new users.
          final isNew = result.additionalUserInfo?.isNewUser ?? false;
          if (isNew) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('academic_info');
            // Also remove from the session cache so MainLayoutScreen will check again.
            checkedUids.remove(result.user?.uid);
          }
          if (context.mounted) context.go('/');
        }
      } on FirebaseAuthException catch (e) {
        ref.read(_loginErrorProvider.notifier).state =
            e.message ?? 'Google sign-in failed.';
      } catch (e) {
        ref.read(_loginErrorProvider.notifier).state =
            e.toString().replaceAll('Exception: ', '');
      } finally {
        ref.read(_isLoadingProvider.notifier).state = false;
      }
    }

    Future<void> handleForgotPassword() async {
      final email = emailCtrl.text.trim();
      if (email.isEmpty) {
        ref.read(_loginErrorProvider.notifier).state =
            'Enter your email above to reset your password.';
        return;
      }
      try {
        await ref.read(authServiceProvider).sendPasswordResetEmail(email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset email sent!'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        ref.read(_loginErrorProvider.notifier).state =
            e.message ?? 'Could not send reset email.';
      }
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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

                    // ── App Name ──────────────────────────────────────────────
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

                    // ── Subtitle ──────────────────────────────────────────────
                    Center(
                      child: Text(
                        'Sign in to your academic portal',
                        style: TextStyle(
                          fontSize: 14,
                          color: dark ? Colors.white60 : const Color(0xFF888888),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Google Button ─────────────────────────────────────────
                    _GoogleSignInButton(
                      onPressed: isLoading ? null : handleGoogleLogin,
                    ),
                    const SizedBox(height: 24),

                    // ── Divider ───────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFDDDDDD),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFDDDDDD),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Email Label ───────────────────────────────────────────
                    Text(
                      'INSTITUTIONAL EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white70 : const Color(0xFF444444),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Email Field ───────────────────────────────────────────
                    _AuthTextField(
                      controller: emailCtrl,
                      hintText: 'student@university.edu',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) =>
                          ref.read(_loginEmailProvider.notifier).state = v,
                    ),
                    const SizedBox(height: 20),

                    // ── Password Label + Forgot ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white70 : const Color(0xFF444444),
                            letterSpacing: 1.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: handleForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Password Field ────────────────────────────────────────
                    _AuthTextField(
                      controller: passCtrl,
                      hintText: '••••••••',
                      obscureText: !passwordVisible,
                      onChanged: (v) =>
                          ref.read(_loginPasswordProvider.notifier).state = v,
                      suffixIcon: GestureDetector(
                        onTap: () => ref
                            .read(_passwordVisibleProvider.notifier)
                            .state = !passwordVisible,
                        child: Icon(
                          passwordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFAAAAAA),
                          size: 20,
                        ),
                      ),
                    ),

                    // ── Error Message ─────────────────────────────────────────
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
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Sign In Button ────────────────────────────────────────
                    _SignInButton(
                      isLoading: isLoading,
                      onPressed: handleEmailLogin,
                    ),
                    const SizedBox(height: 24),

                    // ── Signup Link ───────────────────────────────────────────
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: dark ? Colors.white70 : const Color(0xFF555555),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/signup'),
                            child: const Text(
                              'Request Access',
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

// ─── Reusable Text Field ──────────────────────────────────────────────────────
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
          hintStyle: TextStyle(color: dark ? Colors.white38 : const Color(0xFFBBBBBB), fontSize: 15),
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

// ─── Google Sign-In Button ────────────────────────────────────────────────────
class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? (dark ? const Color(0xFF3A3A40) : const Color(0xFFF5F5F5)) : (dark ? const Color(0xFF2C2C32) : Colors.white),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: dark ? Colors.white12 : const Color(0xFFDDDDDD), width: 1.5),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: dark ? Colors.black54 : Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: widget.onPressed,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter(isDark: isDark(context))),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final bool isDark;

  _GoogleLogoPainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final colors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFF34A853), // Green
      const Color(0xFFFBBC05), // Yellow
      const Color(0xFFEA4335), // Red
    ];

    final startAngles = [-0.1, 1.47, 2.96, 4.48];
    final sweepAngles = [1.57, 1.50, 1.52, 1.65];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        startAngles[i],
        sweepAngles[i],
        false,
        paint,
      );
    }

    final cutPaint = Paint()..color = isDark ? const Color(0xFF2C2C32) : Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.12, r, size.height * 0.24),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Sign In Button ───────────────────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
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
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
