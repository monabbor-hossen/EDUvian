import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_service.dart';
import '../main.dart';
import '../model/routine.dart';
import '../model/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isEditingName = false;
  final _nameController = TextEditingController();
  final _academicController = TextEditingController();
  String _academicInfo = ''; // Will be loaded from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadAcademicInfo();
  }

  Future<void> _loadAcademicInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _academicInfo = prefs.getString('academic_info') ?? '';
      _academicController.text = _academicInfo;
    });
  }

  Future<void> _saveAcademicInfo(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_info', value);
    if (mounted) {
      setState(() {
        _academicInfo = value;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    final isLoggedIn = user != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, "Settings"),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                if (isLoggedIn) ...[
                  Text(
                    "Profile",
                    style: GoogleFonts.poppins(
                      color: dark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                              child: user.photoURL == null ? Text(
                                user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : 'U',
                                style: GoogleFonts.poppins(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                              ) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _isEditingName
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _nameController,
                                          style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87),
                                          decoration: InputDecoration(
                                            hintText: "Enter display name",
                                            hintStyle: GoogleFonts.inter(color: dark ? Colors.white38 : Colors.black38),
                                            isDense: true,
                                            border: const UnderlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _academicController,
                                          textCapitalization: TextCapitalization.characters,
                                          style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87),
                                          decoration: InputDecoration(
                                            hintText: "e.g. 7DCSE.2 or 7DCSE",
                                            hintStyle: GoogleFonts.inter(color: dark ? Colors.white38 : Colors.black38),
                                            isDense: true,
                                            border: const UnderlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    )
                                   : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName?.isNotEmpty == true ? user.displayName! : 'User',
                                          style: GoogleFonts.poppins(
                                            color: dark ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Parsed academic info chips
                                        _AcademicChips(raw: _academicInfo, dark: dark),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email ?? '',
                                          style: GoogleFonts.inter(
                                            color: dark ? Colors.white60 : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditingName ? Icons.check_circle_rounded : Icons.edit_rounded,
                                color: primaryColor,
                              ),
                              onPressed: () async {
                                 if (_isEditingName) {
                                  // Normalise to uppercase before any processing
                                  final raw = _academicController.text.trim().toUpperCase();
                                  // Validate format before saving
                                  if (raw.isNotEmpty && parseAcademicInfo(raw) == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.redAccent.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          content: Text(
                                            'Invalid format. Use e.g. 7DCSE.2 or 7DCSE',
                                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      );
                                    }
                                    return; // Don't save or close editing
                                  }
                                  // Save name and academic info
                                  if (_nameController.text.trim().isNotEmpty) {
                                    await user.updateDisplayName(_nameController.text.trim());
                                  }
                                  if (raw.isNotEmpty) {
                                    await _saveAcademicInfo(raw);
                                    // Invalidate so routineProvider reacts to the new batch ID
                                    ref.invalidate(academicInfoProvider);
                                  }
                                  // ignore: unused_result
                                  ref.refresh(authStateProvider);
                                } else {
                                  _nameController.text = user.displayName ?? '';
                                  _academicController.text = _academicInfo;
                                }
                                setState(() {
                                  _isEditingName = !_isEditingName;
                                });
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Preferences Section
                Text(
                  "Preferences",
                  style: GoogleFonts.poppins(
                    color: dark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: primaryColor,
                        ),
                        title: Text(
                          "Dark Mode",
                          style: GoogleFonts.inter(
                            color: dark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Switch(
                          value: themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && dark),
                          activeColor: primaryColor,
                          onChanged: (value) {
                            ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Auth Actions
                Text(
                  "Account Actions",
                  style: GoogleFonts.poppins(
                    color: dark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  child: ListTile(
                    leading: Icon(
                      isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                      color: isLoggedIn ? Colors.redAccent : primaryColor,
                    ),
                    title: Text(
                      isLoggedIn ? "Log Out" : "Log In",
                      style: GoogleFonts.inter(
                        color: isLoggedIn ? Colors.redAccent : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      if (isLoggedIn) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('academic_info');
                        // ignore: unused_result
                        ref.refresh(academicInfoProvider);
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                      } else {
                        context.push('/login');
                      }
                    },
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AcademicChips — displays parsed Semester / Department / Section chips
// ---------------------------------------------------------------------------
class _AcademicChips extends StatelessWidget {
  final String raw;
  final bool dark;

  const _AcademicChips({required this.raw, required this.dark});

  @override
  Widget build(BuildContext context) {
    final info = parseAcademicInfo(raw);

    if (info == null) {
      // Fallback: just show the raw string if it can't be parsed
      return Text(
        raw,
        style: GoogleFonts.inter(
          color: dark ? Colors.white70 : primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _chip(
          label: 'Semester ${info.semester}',
          icon: Icons.school_rounded,
          color: primaryColor,
          dark: dark,
        ),
        _chip(
          label: info.department,
          icon: Icons.account_balance_rounded,
          color: const Color(0xFF3B1F8F),
          dark: dark,
        ),
        // Only show Section chip when a section number was provided
        if (info.section != null)
          _chip(
            label: 'Section ${info.section}',
            icon: Icons.groups_rounded,
            color: secondaryColor,
            dark: dark,
          ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
