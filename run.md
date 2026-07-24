# Hướng dẫn chạy dự án: Journal Trend Analyzer

Tài liệu này hướng dẫn cách cài đặt, cấu hình và chạy ứng dụng cho toàn bộ thành viên trong nhóm.

---

## 1. Yêu cầu hệ thống (Tiêu chuẩn của nhóm)

Để đảm bảo dự án chạy ổn định và không bị lỗi xung đột, các thành viên nên cài đặt môi trường theo thông số sau:
- **Flutter SDK:** `3.41.9` (Stable channel)
- **Dart SDK:** `3.11.5`
- **JDK:** `21`
- **Android Studio:** Phiên bản mới nhất (đã cài Android SDK và Platform-tools)
- **Firebase Android config:** cần có file `android/app/google-services.json`

---

## 2. Các bước chuẩn bị ban đầu (Cho người mới Pull code)

### Bước 1: Tải các gói thư viện (Dependencies)
Mở Terminal tại thư mục gốc của dự án và chạy lệnh:
```powershell
flutter pub get
```

### Bước 2: Xử lý file cấu hình cá nhân
Nếu bạn gặp lỗi liên quan đến **Android SDK** hoặc **local.properties**, hãy chạy lệnh sau để Flutter tự động tạo lại file cấu hình phù hợp với máy tính của bạn:
```powershell
flutter clean
flutter pub get
```

### Bước 3: Kiểm tra Firebase
Ứng dụng đang gọi `Firebase.initializeApp()` và Android build đang bật plugin `com.google.gms.google-services`, vì vậy khi chạy Android phải có:
```text
android/app/google-services.json
```

Nếu repo nội bộ của nhóm có thể chia sẻ Firebase project chung, hãy commit file này. Nếu repo public, không nên đưa file cấu hình Firebase của project thật lên GitHub; thay vào đó mỗi thành viên tải file từ Firebase Console và đặt đúng đường dẫn trên.

---

## 2. Cách chạy ứng dụng trên thiết bị

### Lựa chọn A: Chạy trên thiết bị Android thật (Ví dụ: OPPO Reno 2F)
1. Kết nối điện thoại với máy tính qua cáp USB (Chọn chế độ **Truyền tệp**).
2. Đảm bảo đã bật **Gỡ lỗi USB (USB Debugging)** trong Tùy chọn nhà phát triển.
3. Kiểm tra danh sách thiết bị:
   ```powershell
   flutter devices
   ```
4. Chạy ứng dụng (Thay ID bằng ID thiết bị của bạn):
   ```powershell
   flutter run -d <DEVICE_ID>
   ```

### Lựa chọn B: Chạy trên trình giả lập (Android Emulator)
1. Mở trình giả lập từ Android Studio.
2. Chạy lệnh:
   ```powershell
   flutter run
   ```
### Lựa chọn C: Chạy trên Web (Dành cho máy cấu hình yếu)
Lưu ý: Firebase hiện mới thấy cấu hình Android qua `google-services.json`. Nếu chạy Web mà gặp lỗi Firebase options, cần cấu hình FlutterFire cho Web trước.
```powershell
flutter run -d chrome
```

---

## 3. Các lệnh "Giải cứu" khi gặp lỗi (Troubleshooting)

Nếu bạn Pull code về mà thấy báo lỗi đỏ hoặc không biên dịch được, hãy chạy combo lệnh sau:

1. **Xóa bộ nhớ đệm và file tạm:**
   ```powershell
   flutter clean
   ```
2. **Tải lại toàn bộ thư viện:**
   ```powershell
   flutter pub get
   ```
3. **Cập nhật cấu hình hệ thống:**
   ```powershell
   flutter doctor
   ```

---

## 4. Lưu ý khi làm việc nhóm (Git & Sync)

- **KHÔNG** đẩy các file cá nhân lên GitHub: Những file như `local.properties` hay thư mục `.idea/` đã được chặn bởi `.gitignore`, đừng cố tình xóa chặn để đẩy lên.
- **Luôn Clean trước khi Build:** Nếu bạn thấy giao diện không cập nhật đúng như người khác đã làm, hãy dùng `flutter clean` trước khi chạy lại.
- **Thống nhất phiên bản:** Khuyến nghị cả nhóm dùng chung Flutter `3.41.9`, Dart `3.11.5` và JDK `21` để tránh xung đột file `.metadata` hoặc lỗi Gradle.

---

*Chúc nhóm hoàn thành tốt dự án!*
lệnh chạy web flutter run -d chrome