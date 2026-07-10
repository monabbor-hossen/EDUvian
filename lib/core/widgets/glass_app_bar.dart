import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

AppBar appBar(BuildContext context, String title) {
  final dark = isDark(context);
  final textColor = dark ? Colors.white : primaryColor;
  
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    title: Text(
      title,
      style: GoogleFonts.poppins(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    ),
    leading: GoRouter.of(context).canPop()
        ? IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          )
        : null,
    centerTitle: true,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: dark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3)),
      ),
    ),
  );
}
