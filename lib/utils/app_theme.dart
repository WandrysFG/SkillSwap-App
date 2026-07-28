import 'package:flutter/material.dart';

class AppColors {
  static const cyan = Color(0xFF12C2E9);
  static const blue = Color(0xFF1E6FE0);
  static const deepBlue = Color(0xFF0D47A1);
  static const bgLight = Color(0xFFEAF6FB);

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