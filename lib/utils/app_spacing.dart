import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // ==========================================================================
  // HỖ TRỢ SIZEDBOX (Tiện ích tạo khoảng trống nhanh)
  // ==========================================================================
  
  // Khoảng trống theo chiều dọc (Vertical Spacing)
  static const SizedBox vSpacingXs = SizedBox(height: xs);
  static const SizedBox vSpacingSm = SizedBox(height: sm);
  static const SizedBox vSpacingMd = SizedBox(height: md);
  static const SizedBox vSpacingLg = SizedBox(height: lg);
  static const SizedBox vSpacingXl = SizedBox(height: xl);

  // Khoảng trống theo chiều ngang (Horizontal Spacing)
  static const SizedBox hSpacingXs = SizedBox(width: xs);
  static const SizedBox hSpacingSm = SizedBox(width: sm);
  static const SizedBox hSpacingMd = SizedBox(width: md);
  static const SizedBox hSpacingLg = SizedBox(width: lg);

  // ==========================================================================
  // ĐỘ BO GÓC (Border Radius)
  // ==========================================================================
  
  /// Bo góc nhỏ (8.0) - Dùng cho ô nhập liệu (TextField), các nhãn/tag phân loại bài báo.
  static final BorderRadius radiusSm = BorderRadius.circular(8.0);
  static const double radiusSmValue = 8.0;
  
  /// Bo góc vừa (12.0) - Dùng cho các nút bấm hành động chính (Primary Button), các hộp thoại (Dialog).
  static final BorderRadius radiusMd = BorderRadius.circular(12.0);
  static const double radiusMdValue = 12.0;
  
  /// Bo góc lớn (16.0) - Dùng cho các khối Card bài báo, khung chứa đồ thị phân tích trên Dashboard.
  static final BorderRadius radiusLg = BorderRadius.circular(16.0);
  static const double radiusLgValue = 16.0;
}