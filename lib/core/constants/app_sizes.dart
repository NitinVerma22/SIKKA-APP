import 'package:flutter/material.dart';

/// Centralized layout tokens for consistent paddings, margins, sizes, and borders.
class AppSizes {
  // Spacing & Padding
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;
  static const double radiusCircular = 999.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Layout Boundaries
  static const double maxContentWidth = 600.0;

  /// Responsive padding helper based on screen width
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return lg;
    if (width < 360) return sm;
    return md;
  }

  /// Responsive text scaler helper
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final double width = MediaQuery.of(context).size.width;
    if (width > 600) return baseSize * 1.15;
    if (width < 360) return baseSize * 0.90;
    return baseSize;
  }
}
