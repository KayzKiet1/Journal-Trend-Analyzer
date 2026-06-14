import 'package:flutter/material.dart';

class AppColors {
  // === MÀU CHỦ ĐẠO THIẾT KẾ (HERITAGE THEME) ===
  
  /// Màu chính (Deep Ink): #1A1C1E - Headlines, core body text, icons
  static const Color primary = Color(0xFF1A1C1E);
  
  /// Màu phụ (Sophisticated Slate): #6C7278 - Borders, captions, meta-data
  static const Color secondary = Color(0xFF6C7278); 
  
  /// Màu nhấn (Boston Clay): #B8422E - Primary CTAs, active states, chart lines
  static const Color accent = Color(0xFFB8422E);
  
  /// Màu nền (Warm Limestone / Neutral): #F7F5F2 - Main application background
  static const Color background = Color(0xFFF7F5F2);
  
  /// Màu bề mặt (Paper White / Surface): #FFFFFF - Cards, modal sheets, input fields
  static const Color surface = Color(0xFFFFFFFF);
  
  // === MÀU TRẠNG THÁI HỆ THỐNG ===
  static const Color success = Color(0xFF15803D); 
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFF991B1B);   
  
  // === MÀU VĂN BẢN (TYPOGRAPHY) ===
  /// Chữ chính: Dùng màu primary (Deep Ink)
  static const Color textPrimary = primary;
  
  /// Chữ phụ: Dùng màu secondary (Sophisticated Slate)
  static const Color textSecondary = secondary;
  
  /// Chữ đảo ngược (Hiển thị trên nền tối hoặc nút nhấn)
  static const Color textInverted = background;
  
  /// Màu cho Tag hoặc Thẻ nhẹ (Tùy chọn thêm để giữ tính tương thích)
  static const Color accentLight = Color(0xFFFBEBE9); 
}
