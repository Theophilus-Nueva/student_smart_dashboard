import 'package:flutter/material.dart';

/// Colours taken from the Figma file (Components section).
class AppColors {
  AppColors._();

  static const brand = Color(0xFFB71C1C);
  static const surface = Colors.white;
  static const background = Color(0xFFF5F5F5);
  static const border = Color(0xFFE0E0E0);
  static const field = Color(0xFFF2F2F2);
  static const text = Color(0xFF111111);
  static const muted = Color(0xFF616161);
  static const tabActive = Color(0xFF3949AB);
  static const badge = Color(0xFFFFD54F);

  // Network status (Week 7): green / amber / red.
  static const online = Color(0xFF2E7D32);
  static const onlineBg = Color(0xFFE8F5E9);
  static const pending = Color(0xFFB26A00);
  static const pendingBg = Color(0xFFFFF4E0);
  static const offline = Color(0xFFC62828);
  static const offlineBg = Color(0xFFFDECEA);
}
