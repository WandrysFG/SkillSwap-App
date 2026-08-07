import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF12C2E9);
  static const blue = Color(0xFF1E6FE0);
  static const deepBlue = Color(0xFF0D47A1);
  static const bgLight = Color(0xFFEAF6FB);

  // 🆕 Colores semánticos de estado
  static const success = Color(0xFF3B9E5F);
  static const successBg = Color(0xFFE7F5EC);
  static const warning = Color(0xFFE0A030);
  static const warningBg = Color(0xFFFBF1DE);
  static const danger = Color(0xFFD84A3E);
  static const dangerBg = Color(0xFFFBE9E7);
  static const neutral = Color(0xFF6B7280);
  static const neutralBg = Color(0xFFF1F2F4);

  // 🆕 Superficies
  static const cardBg = Colors.white;
  static const cardBorder = Color(0xFFE7EEF5);

  // 🆕 Paleta de colores para avatares (se elige por hash del nombre)
  static const avatarPalette = [
    Color(0xFFEF6461), // rojo/coral (como "CL" en tu mockup)
    Color(0xFF8B5CF6), // púrpura (como "SM")
    Color(0xFF6366F1), // índigo (como "JO")
    Color(0xFFF59E0B), // naranja (como "LR")
    Color(0xFF12C2E9), // cyan
    Color(0xFF3B9E5F), // verde
  ];

  static const primaryGradient = LinearGradient(
    colors: [cyan, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFE3F6FC), Color(0xFFDCEBFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppInputStyle {
  static InputDecoration decoration({required String hint, required IconData icon, Widget? suffix}) {
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