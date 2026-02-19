import 'dart:ui';

/// Цветовая палитра приложения Dating Coach
abstract class AppColors {
  // Background
  static const Color background = Color(0xFFFFE8D1);
  
  // Primary (тёмно-синий акцентный)
  static const Color primary = Color(0xFF1B3A57);
  
  // Action (тёмный персиковый для главных кнопок)
  static const Color action = Color(0xFFD4784A);
  
  // Text
  static const Color textPrimary = Color(0xFF1F2A37);
  static const Color textSecondary = Color(0xFF6B7A8C);
  
  // Accent (синоним primary для совместимости)
  static const Color accent = primary;
  
  // Surface (для карточек, модалок — как основной фон)
  static const Color surface = background;
  
  // Input (для полей ввода — чуть темнее фона)
  static const Color inputBackground = Color(0xFFF5D9BC);
  
  // Utility
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Border
  static const Color border = Color(0xFFEDD5BB);
}
