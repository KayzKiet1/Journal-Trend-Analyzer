import 'package:flutter/material.dart';

class AppColors {
  // === MÀU CHỦ ĐẠO (HERITAGE M3) ===
  
  /// Primary: Deep Ink (#1A1C1E) - Dùng cho tiêu đề chính, điều hướng
  static const Color primary = Color(0xFF1A1C1E);
  
  /// Secondary: Sophisticated Slate (#6C7278) - Dùng cho văn bản phụ
  static const Color secondary = Color(0xFF6C7278); 
  
  /// Accent/Tertiary: Boston Clay (#B8422E) - Màu nhấn cho nút, link, biểu đồ
  static const Color accent = Color(0xFFB8422E);
  
  // === HỆ THỐNG NỀN (M3 TONAL SURFACES) ===
  
  /// Background: Warm Limestone (#F7F5F2) - Nền thấp nhất (Level 0)
  static const Color background = Color(0xFFF7F5F2);
  
  /// Surface: Paper White (#FFFFFF) - Nền cho thẻ Card, Modal (Level 1)
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface Variant: Màu xám nhẹ hơn để phân tách các vùng nội dung (Level 2)
  static const Color surfaceVariant = Color(0xFFEEEBE6);
  
  /// Outline: Màu viền mảnh theo chuẩn M3
  static const Color outline = Color(0xFFD1CFCC);

  // === TRẠNG THÁI ===
  static const Color success = Color(0xFF15803D); 
  static const Color error = Color(0xFF991B1B);   
  
  // === VĂN BẢN ===
  static const Color textPrimary = primary;
  static const Color textSecondary = secondary;
  static const Color textInverted = Color(0xFFFFFFFF);
}
