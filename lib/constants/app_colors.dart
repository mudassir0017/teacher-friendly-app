import 'package:flutter/material.dart';

// Color Constants for Teacher App
// Use these constants throughout the app for consistency

class AppColors {
  // Primary Colors
  static const primaryIndigo = Color(0xFF6366F1);
  static const secondaryPurple = Color(0xFF8B5CF6);
  static const accentBlue = Color(0xFF3B82F6);
  
  // Functional Colors
  static const successGreen = Color(0xFF10B981);
  static const warningAmber = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
  
  // Neutral Colors
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  
  // Background Colors
  static const backgroundPrimary = Color(0xFFF8FAFC);
  static const backgroundSecondary = Color(0xFFFFFFFF);
  static const backgroundTertiary = Color(0xFFF1F5F9);
  
  // Border Colors
  static const borderLight = Color(0xFFE2E8F0);
  static const borderMedium = Color(0xFFCBD5E1);
  
  // Gradient Combinations
  static const gradientPurpleIndigo = [Color(0xFF8B5CF6), Color(0xFF6366F1)];
  static const gradientAmberRed = [Color(0xFFF59E0B), Color(0xFFEF4444)];
  static const gradientIndigoBlue = [Color(0xFF6366F1), Color(0xFF3B82F6)];
}

// Usage Example:
// Container(
//   decoration: BoxDecoration(
//     gradient: LinearGradient(
//       colors: AppColors.gradientPurpleIndigo,
//     ),
//   ),
// )
