import 'package:flutter/material.dart';

class AppColors {
  // Sunset Gradient Colors
  static const Color red950 = Color(0xFFEF5F0C);
  static const Color red900 = Color(0xFFEF5F0C);
  static const Color red800 = Color(0xFFEF5F0C);
  static const Color orange950 = Color(0xFFEF5F0C);
  static const Color orange900 = Color(0xFFEF5F0C);
  static const Color orange800 = Color(0xFFEF5F0C);
  static const Color orange600 = Color(0xFFEF5F0C);
  static const Color orange500 = Color(0xFFEF5F0C);

  // Surfaces / separators for light UI
  static const Color glass = Colors.white;
  static const Color glassBorder = Color(0x14000000); // ~8% black

  // Text Colors (dark on light background)
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF4B5563); // gray-600
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400

  // Status Colors
  static const Color success = Color(0xFF22c55e);
  static const Color warning = Color(0xFFf59e0b);
  static const Color error = Color(0xFFef4444);
  static const Color info = Color(0xFF3b82f6);

  // Gradients
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red950, orange950, red900],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33ffffff), Color(0x1affffff)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange600, orange800],
  );
}
