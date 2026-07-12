import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../models/academic_info.dart';
import '../services/notification_service.dart';

/// Shows the first-time academic info setup dialog.
/// Returns `true` if the user saved, `false` if they cancelled.
Future<bool> showAcademicInfoSetupDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => const _AcademicInfoSetupDialog(),
  );
  return result == true;
}

class _AcademicInfoSetupDialog extends StatefulWidget {
  const _AcademicInfoSetupDialog();

  @override
  State<_AcademicInfoSetupDialog> createState() =>
      _AcademicInfoSetupDialogState();
}

class _AcademicInfoSetupDialogState extends State<_AcademicInfoSetupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saving = false;
  String? _errorText;
  String? _nameErrorText;
  bool _needsName = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scaleAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.displayName == null || user.displayName!.trim().isEmpty)) {
      _needsName = true;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _textController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    
    if (raw.isEmpty) return;
    if (_needsName && name.isEmpty) return;

    bool hasError = false;
    
    if (parseAcademicInfo(raw) == null) {
      setState(() => _errorText = 'Invalid format. Use e.g. 7DCSE.2');
      hasError = true;
    } else {
      setState(() => _errorText = null);
    }
    
    if (_needsName && name.isEmpty) {
      setState(() => _nameErrorText = 'Name is required');
      hasError = true;
    } else {
      setState(() => _nameErrorText = null);
    }
    
    if (hasError) return;

    setState(() {
      _saving = true;
      _errorText = null;
      _nameErrorText = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('academic_info', raw);
    
    // Parse the raw batch string for structured Firestore fields
    final info = parseAcademicInfo(raw);
    
    // Also persist to Firestore so reinstalls / new devices skip the popup.
    // We save both the raw string AND structured queryable fields so classmate
    // queries can use compound Firestore filters.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    if (uid != null) {
      try {
        if (_needsName && name.isNotEmpty) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
          await FirebaseAuth.instance.currentUser?.reload();
        }
        
        final dataToSave = <String, dynamic>{
          'academic_info': raw,
        };
        
        if (_needsName && name.isNotEmpty) {
          dataToSave['name'] = name;
        }
        
        if (info != null) {
          // Determine shift from email (ends with 'e' before domain = Evening)
          final localPart = userEmail.split('@').first.toLowerCase();
          final shift = localPart.endsWith('e') ? 'Evening' : 'Regular';
          
          await prefs.setString('shift', shift); // Store shift in SharedPreferences for routine generating
          
          dataToSave['semester']   = info.semester;
          dataToSave['department'] = shift == 'Evening' ? 'EBSC in CSE' : 'BSC in CSE';
          dataToSave['section']    = info.section;
          dataToSave['shift']      = shift;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(dataToSave, SetOptions(merge: true));
      } catch (_) {
        // Non-blocking — local save already succeeded
      }
    }

    // Subscribe to batch topic (routine updates) and official chat topic
    if (info != null) {
      final localPart = userEmail.split('@').first.toLowerCase();
      final shift = localPart.endsWith('e') ? 'Evening' : 'Regular';
      
      NotificationService().subscribeToBatchTopic(raw, shift: shift);
      
      NotificationService().subscribeToOfficialChatTopic(
        semester:   info.semester,
        department: shift == 'Evening' ? 'EBSC in CSE' : 'BSC in CSE', 
        section:    info.section,
        shift:      shift,          
      );
    }
    
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1A0A14) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: dark
                    ? primaryColor.withValues(alpha: 0.35)
                    : primaryColor.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: dark ? 0.25 : 0.12),
                  blurRadius: 40,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                       mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // ── Icon ───────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                const Color(0xFF3B1F8F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Title ──────────────────────────────────────────────
                      Text(
                        'Set Up Your Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF1A0A14),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your academic info to personalise your routine. You can change this anytime in Settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: dark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Name Field (Optional) ───────────────────────────────
                      if (_needsName) ...[
                        _label('FULL NAME', dark),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.inter(
                            color: dark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'John Doe',
                            hintStyle: GoogleFonts.inter(
                              color: dark ? Colors.white38 : Colors.black38,
                            ),
                            errorText: _nameErrorText,
                            filled: true,
                            fillColor: dark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            if (_nameErrorText != null) {
                              setState(() => _nameErrorText = null);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Single Text Field ──────────────────────────────────
                      _label('ACADEMIC INFO', dark),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        style: GoogleFonts.inter(
                          color: dark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. 7DCSE.2',
                          hintStyle: GoogleFonts.inter(
                            color: dark ? Colors.white38 : Colors.black38,
                          ),
                          errorText: _errorText,
                          filled: true,
                          fillColor: dark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: primaryColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (_errorText != null) {
                              _errorText = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Action Buttons ─────────────────────────────────────
                      Row(
                        children: [
                          // Cancel
                          Expanded(
                            child: TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Skip for now',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      dark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save
                          Expanded(
                            flex: 2,
                            child: AnimatedOpacity(
                              opacity: (_textController.text.trim().isNotEmpty && (!_needsName || _nameController.text.trim().isNotEmpty)) ? 1.0 : 0.45,
                              duration: const Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed: (_textController.text.trim().isNotEmpty && (!_needsName || _nameController.text.trim().isNotEmpty) && !_saving) ? _save : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      primaryColor.withValues(alpha: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 4,
                                  shadowColor:
                                      primaryColor.withValues(alpha: 0.4),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Save & Continue',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool dark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: dark ? Colors.white54 : Colors.black45,
        ),
      );
}

class PickerDropdown<T> extends StatelessWidget {
  final bool dark;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const PickerDropdown({
    super.key,
    required this.dark,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: dark ? const Color(0xFF24101C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: dark ? Colors.white54 : primaryColor.withValues(alpha: 0.7)),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: dark ? Colors.white : const Color(0xFF1A0A14),
          ),
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: dark ? Colors.white30 : Colors.black38,
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
