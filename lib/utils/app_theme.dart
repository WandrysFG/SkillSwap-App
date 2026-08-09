import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF0891B2);
  static const blue = Color(0xFF1D4ED8);
  static const deepBlue = Color(0xFF0F172A);
  static const bgLight = Color(0xFFE0F2FE);

  static const success = Color(0xFF3B9E5F);
  static const successBg = Color(0xFFE7F5EC);
  static const warning = Color(0xFFE0A030);
  static const warningBg = Color(0xFFFBF1DE);
  static const danger = Color(0xFFD84A3E);
  static const dangerBg = Color(0xFFFBE9E7);
  static const neutral = Color(0xFF6B7280);
  static const neutralBg = Color(0xFFF1F2F4);

  static const cardBg = Colors.white;
  static const cardBorder = Color(0xFFE2E8F0);

  static const navBarBg = deepBlue;

  static const avatarPalette = [
    Color(0xFFEF6461),
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF0891B2),
    Color(0xFF3B9E5F),
  ];

  static const primaryGradient = LinearGradient(
    colors: [blue, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFD3E3FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Sombra con tinte de marca en vez de gris neutro
  static Color cardShadow = blue.withOpacity(0.08);
}

class AppInputStyle {
  static InputDecoration decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.blue),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    );
  }
}