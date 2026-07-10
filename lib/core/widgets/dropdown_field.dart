import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'rounded_field.dart';

class DropdownField extends ConsumerWidget {
  final StateProvider<String?> ProviderName;
  final List<String> item;
  final String? hintText;
  final void Function(WidgetRef ref, String?)? onChangeExtra;
  const DropdownField({
    super.key,
    required this.ProviderName,
    required this.item,
    this.hintText,
    this.onChangeExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectValue = ref.watch(ProviderName);
    final dark = isDark(context);
    return DropdownButtonFormField<String>(
      initialValue: selectValue,
      decoration: inputDecoration(),
      dropdownColor: dark ? const Color(0xFF2C2C32) : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: dark ? Colors.white70 : primaryColor),
      style: GoogleFonts.inter(color: dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      borderRadius: BorderRadius.circular(16),
      items: [
        if (hintText != null)
          DropdownMenuItem<String>(
            value: null,
            child: Text(hintText!, style: TextStyle(color: dark ? Colors.white54 : Colors.black45)),
          ),
        ...item.map((value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
      ],
      onChanged: (newValue) {
        ref.read(ProviderName.notifier).state = newValue;
        if (onChangeExtra != null) {
          onChangeExtra!(ref, newValue);
        }
      },
    );
  }
}

InputDecoration fieldDecoration(BuildContext context, {String? hint, IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: isDark(context) ? Colors.white54 : Colors.black45),
      prefixIcon: icon != null ? Icon(icon, color: primaryColor.withValues(alpha: 0.7)) : null,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
