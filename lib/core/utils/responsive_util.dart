import 'package:flutter/widgets.dart';

extension ResponsiveContext on BuildContext {
  /// Screen Dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Breakpoints
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Responsive Proportions
  double wp(double percentage) => screenWidth * (percentage / 100);
  double hp(double percentage) => screenHeight * (percentage / 100);

  /// Dynamic Font Sizing
  double responsiveFontSize(double baseSize) {
    if (isMobile) return baseSize;
    if (isTablet) return baseSize * 1.15;
    return baseSize * 1.3;
  }

  /// Max Constraint for Content
  double get maxContentWidth => isDesktop ? 1000 : (isTablet ? 700 : screenWidth);
}
