import 'package:flutter/material.dart';

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

const primaryColor = Color.fromRGBO(107, 0, 50, 1);
const secondaryColor = Color.fromRGBO(209, 61, 89, 1); // vibrant maroon accent
const offWhite = Color.fromRGBO(255, 249, 242, 1);
final glassWhite = Colors.white.withValues(alpha: 0.4);
final glassShadow = Colors.black.withValues(alpha: 0.05);
