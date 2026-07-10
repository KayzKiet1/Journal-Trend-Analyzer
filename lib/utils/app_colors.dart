import 'package:flutter/material.dart';

class AppColors {
  // === MÀU CHỦ ĐẠO THIẾT KẾ (RESEARCH ANALYTICS THEME) ===

  /// Màu chính (Scholar Ink): #14213D - Headlines, core body text, icons
  static const Color primary = Color(0xFF14213D);

  /// Màu chính mềm hơn cho các mảng nền có chiều sâu.
  static const Color primarySoft = Color(0xFF203456);

  /// Màu phụ (Data Slate): #64748B - Borders, captions, meta-data
  static const Color secondary = Color(0xFF64748B);

  /// Màu nhấn (Citation Teal): #0F766E - Primary CTAs, active states, chart lines
  static const Color accent = Color(0xFF0F766E);

  /// Màu nhấn đậm cho gradient CTA.
  static const Color accentDark = Color(0xFF0B5F59);

  /// Màu nền (Lab Mist): #F5F8FA - Main application background
  static const Color background = Color(0xFFF0F5F7);

  /// Màu bề mặt (Paper White / Surface): #FFFFFF - Cards, modal sheets, input fields
  static const Color surface = Color(0xFFFFFFFF);

  /// Màu bề mặt phụ cho chip, trạng thái nhạt và vùng phụ trợ.
  static const Color surfaceTint = Color(0xFFF7FBFA);

  /// Viền tinh tế hơn Data Slate nguyên bản.
  static const Color border = Color(0xFFD7E2EA);

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
  static const Color accentLight = Color(0xFFE0F5F2);
}
