import 'package:flutter/material.dart';

class AppColors {
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color orange600 = Color(0xFFEA580C);

  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x1A000000);

  static const Gradient buttonGradient = LinearGradient(
    colors: [Color(0xFFFF8C3B), Color(0xFFFF5C5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
