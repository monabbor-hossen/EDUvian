import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_service.dart';
import '../main.dart';
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
  String _academicInfo = '7DCSE.2'; // Default academic info

  @override
  void initState() {
    super.initState();
    _loadAcademicInfo();
  }

  Future<void> _loadAcademicInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _academicInfo = prefs.getString('academic_info') ?? '7DCSE.2';
      _academicController.text = _academicInfo;
    });
  }

  Future<void> _saveAcademicInfo(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_info', value);
    setState(() {
      _academicInfo = value;
    });
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
                                          style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87),
                                          decoration: InputDecoration(
                                            hintText: "e.g. 7DCSE.2",
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
                                        const SizedBox(height: 2),
                                        Text(
                                          _academicInfo,
                                          style: GoogleFonts.inter(
                                            color: dark ? Colors.white70 : primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
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
                                  // Save name and academic info
                                  if (_nameController.text.trim().isNotEmpty) {
                                    await user.updateDisplayName(_nameController.text.trim());
                                  }
                                  await _saveAcademicInfo(_academicController.text.trim());
                                  
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
