import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6E5DE7); // Royal Purple
  static const Color primaryLight = Color(0xFF9285F4);
  static const Color secondary = Color(0xFF00E5FF); // Vibrant Cyan
  static const Color accent = Color(0xFFFF9E00); // Reward Orange
  static const Color yellowGlow = Color(0xFFFFD600); // Coin Yellow
  static const Color success = Color(0xFF4CAF50); // Success Green

  // Neutral Backgrounds
  static const Color background =
      Color(0xFFF7F8FC); // Light Soft Lavender/Blue-grey
  static const Color cardBg = Colors.white;
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E2E); // Sleek Dark Navy
  static const Color textSecondary = Color(0xFF757691); // Cool Muted Grey
  static const Color textLight = Color(0xFFACADC0); // Light Hint Grey

  // Border & Divider
  static const Color borderLight =
      Color(0xFFEBEBF5); // Super light subtle border

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8F00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [accent, yellowGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softCardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF0EFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassLikeGradient = LinearGradient(
    colors: [
      Color(0x99FFFFFF),
      Color(0x33FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: accent.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
      spreadRadius: 2,
    ),
  ];
}
