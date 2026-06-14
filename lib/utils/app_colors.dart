import 'package:flutter/material.dart';

class AppColors {
  // === MÀU CHỦ ĐẠO THIẾT KẾ (HERITAGE THEME) ===
  /// Màu nhấn chính: Boston Clay (#B8422E) - Đỏ đất gạch cổ điển
  static const Color primary = Color(0xFFB8422E);
  
  /// Màu nền bổ trợ sáng: Dùng làm nền nhẹ cho Tag hoặc Thẻ (Thế chỗ cho màu xanh nhạt cũ)
  static const Color primaryLight = Color(0xFFFBEBE9); 
  
  /// Màu phụ: Xám đá chẻ trung tính (#64748B) - Giữ nguyên hoặc làm trầm lại một chút
  static const Color secondary = Color(0xFF57534E); 
  
  /// Màu tương phản cao/Nhấn phụ: Chuyển sang tông đỏ sậm hoặc cam đất thay vì màu xanh dương cũ
  static const Color accent = Color(0xFF991B1B);
  
  // === MÀU NỀN VÀ BỀ MẶT ===
  /// Màu nền chính: Warm Limestone (#F7F5F2) - Tông trắng ấm đặc trưng của Heritage
  static const Color background = Color(0xFFF7F5F2);
  
  /// Màu bề mặt các thẻ (Cards, Containers): Màu trắng tinh để nổi bật trên nền Limestone
  static const Color surface = Color(0xFFFFFFFF);
  
  // === MÀU TRẠNG THÁI HỆ THỐNG ===
  static const Color success = Color(0xFF15803D); // Xanh lá đậm học thuật
  static const Color warning = Color(0xFFB45309); // Cam đất cảnh báo
  static const Color error = Color(0xFF991B1B);   // Đỏ thẫm báo lỗi
  
  // === MÀU VĂN BẢN (TYPOGRAPHY) ===
  /// Chữ chính: Đen than đá thẫm (#1C1917) đem lại độ tương phản cực kỳ cao trên nền giấy ấm
  static const Color textPrimary = Color(0xFF1C1917);
  
  /// Chữ phụ: Xám đá bùn sâu lắng cho các đoạn mô tả nhỏ, tên tác giả, tạp chí
  static const Color textSecondary = Color(0xFF57534E);
  
  /// Chữ đảo ngược (Hiển thị trên nền Appbar đỏ hoặc nút bấm đỏ)
  static const Color textInverted = Color(0xFFFFFFFF);
}