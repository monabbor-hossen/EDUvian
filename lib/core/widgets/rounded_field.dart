import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

class RoundedField extends StatelessWidget {
  final Widget child;
  const RoundedField({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      alpha: 0.6,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

InputDecoration inputDecoration() => InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
