# Hướng dẫn chạy dự án (Android)

Tài liệu này hướng dẫn cách cài đặt và chạy ứng dụng Journal Trend Analyzer trên môi trường Android.

## 1. Yêu cầu hệ thống
- **Flutter SDK**: Đã được cài đặt và cấu hình biến môi trường (`path`).
- **Android SDK & Emulator**: Đã cài đặt Android Studio và tạo ít nhất một thiết bị giả lập (hoặc kết nối thiết bị thật).

## 2. Các bước thực hiện

### Bước 1: Lấy mã nguồn về máy
```bash
git clone <url-cua-repo>
cd Journal-Trend-Analyzer
```

### Bước 2: Tải các gói phụ thuộc (Dependencies)
Mở terminal tại thư mục gốc của dự án và chạy lệnh:
```bash
flutter pub get
```

### Bước 3: Kiểm tra thiết bị đang kết nối
Đảm bảo rằng thiết bị giả lập hoặc thiết bị thật đã sẵn sàng:
```bash
flutter devices
```

### Bước 4: Chạy ứng dụng
Chạy lệnh sau để khởi động ứng dụng trên thiết bị Android:
```bash
flutter run
```

*Lưu ý: Nếu có nhiều thiết bị, bạn có thể chỉ định ID thiết bị bằng cách dùng `-d <device-id>`, ví dụ: `flutter run -d emulator-5554`.*

## 3. Cấu trúc dự án (Android Only)
Dự án này đã được tối ưu hóa để tập trung vào nền tảng Android. Các thư mục quan trọng:
- `lib/`: Chứa mã nguồn Dart chính.
- `android/`: Cấu hình nền tảng Android.
- `pubspec.yaml`: Khai báo các thư viện sử dụng trong dự án.
