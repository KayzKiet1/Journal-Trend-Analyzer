import 'package:flutter/material.dart';

class AppColors {
  // === MÀU CHỦ ĐẠO THIẾT KẾ (RESEARCH ANALYTICS THEME) ===

  /// Màu chính (Scholar Ink): #14213D - Headlines, core body text, icons
  static const Color primary = Color(0xFF14213D);

  /// Màu phụ (Data Slate): #64748B - Borders, captions, meta-data
  static const Color secondary = Color(0xFF64748B);

  /// Màu nhấn (Citation Teal): #0F766E - Primary CTAs, active states, chart lines
  static const Color accent = Color(0xFF0F766E);

  /// Màu nền (Lab Mist): #F5F8FA - Main application background
  static const Color background = Color(0xFFF5F8FA);

  /// Màu bề mặt (Paper White / Surface): #FFFFFF - Cards, modal sheets, input fields
  static const Color surface = Color(0xFFFFFFFF);

  // === MÀU TRẠNG THÁI HỆ THỐNG ===
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFF991B1B);

  // === MÀU VĂN BẢN (TYPOGRAPHY) ===
  /// Chữ chính: Dùng màu primary (Scholar Ink)
  static const Color textPrimary = primary;

  /// Chữ phụ: Dùng màu secondary (Data Slate)
  static const Color textSecondary = secondary;

  /// Chữ đảo ngược (Hiển thị trên nền tối hoặc nút nhấn)
  static const Color textInverted = background;

  /// Màu cho Tag hoặc Thẻ nhẹ (Tùy chọn thêm để giữ tính tương thích)
  static const Color accentLight = Color(0xFFE0F2F1);
}
