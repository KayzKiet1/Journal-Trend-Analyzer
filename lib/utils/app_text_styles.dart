import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  /// H1 - Tiêu đề lớn nhất (24px, Bold)
  /// Dùng cho tiêu đề chính ở HomeScreen hoặc tiêu đề tổng của màn hình Dashboard.
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 32.0 / 24.0, // Tương đương lineHeight 32px
  );

  /// H2 - Tiêu đề vừa (18px, Semi-Bold)
  /// Dùng cho tiêu đề của từng Card bài báo khoa học hoặc tiêu đề các phân mục lớn.
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 24.0 / 18.0, // Tương đương lineHeight 24px
  );

  /// Body Large - Văn bản lớn (16px, Regular)
  /// Dùng cho nội dung đoạn tóm tắt (Abstract text) trong màn hình chi tiết bài báo.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 22.0 / 16.0, // Tương đương lineHeight 22px
  );

  /// Body Medium - Văn bản tiêu chuẩn (14px, Regular)
  /// Dùng cho thông tin Metadata như Tên tạp chí, Danh sách tác giả hoặc đoạn văn bản thường.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 20.0 / 14.0, // Tương đương lineHeight 20px
  );

  /// Caption - Văn bản nhỏ ghi chú (12px, Medium)
  /// Dùng cho số lượng trích dẫn (Citation count), Năm xuất bản nhỏ nằm trong các thẻ Tag.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 16.0 / 12.0, // Tương đương lineHeight 16px
  );

  // ==========================================================================
  // CÁC BIẾN THỂ ĐẶC BIỆT (Special Variants)
  // ==========================================================================

  /// Kiểu chữ dùng riêng cho văn bản hiển thị bên trong các nút bấm chính (Primary Button).
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textInverted,
  );

  /// Kiểu chữ hiển thị số liệu lớn trên các thẻ StatCard (ví dụ: số lượng bài báo "142").
  static const TextStyle statValue = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}