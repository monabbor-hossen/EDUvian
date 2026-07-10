import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double alpha;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.alpha = 0.5,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: dark ? Colors.black.withValues(alpha: alpha * 0.7) : Colors.white.withValues(alpha: alpha),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? (dark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withValues(alpha: 0.2) : glassShadow,
                  blurRadius: 24,
                  spreadRadius: -4,
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
