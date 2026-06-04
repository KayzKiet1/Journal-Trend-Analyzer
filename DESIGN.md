---
name: Journal Trend Analyzer Design System
description: Academic mobile design system for analyzing and exploring research publication trends.
version: 1.0.0

colors:
  # Tone màu chính mang tính công nghệ và học thuật
  primary: "#1E3A8A"        # Deep Blue (Dùng cho AppBar, nút chính, điểm nhấn đồ thị)
  primaryLight: "#EFF6FF"   # Light Blue (Dùng cho background của stat card, highlight)
  secondary: "#64748B"      # Slate Gray (Dùng cho icon phụ, text phụ)
  accent: "#2563EB"         # Royal Blue (Dùng cho liên kết, trạng thái active)
  
  # Màu nền hệ thống
  background: "#F8FAFC"     # Off-White (Màu nền của toàn bộ ứng dụng)
  surface: "#FFFFFF"        # Pure White (Màu nền của các thẻ Card bài báo, Dashboard)
  
  # Màu trạng thái hệ thống
  success: "#16A34A"        # Green (Trạng thái tải thành công, số liệu tăng trưởng)
  warning: "#F59E0B"        # Amber (Cảnh báo rỗng)
  error: "#DC2626"          # Red (Trạng thái lỗi API, mất kết nối mạng)
  
  # Màu chữ (Typography colors)
  textPrimary: "#0F172A"    # Dark Slate (Tiêu đề bài báo, nội dung chính)
  textSecondary: "#475569"  # Muted Slate (Tên tác giả, năm xuất bản, chỉ số phụ)
  textInverted: "#FFFFFF"   # White text trên nền tối

typography:
  fontFamily: "Roboto"
  styles:
    h1:
      fontSize: 24px
      fontWeight: 700
      lineHeight: 32px
      description: "Dùng cho tiêu đề lớn ở HomeScreen hoặc màn hình Dashboard tổng"
    h2:
      fontSize: 18px
      fontWeight: 600
      lineHeight: 24px
      description: "Dùng cho tiêu đề của từng Card bài báo, tiêu đề phân mục lớn"
    bodyLarge:
      fontSize: 16px
      fontWeight: 400
      lineHeight: 22px
      description: "Dùng cho nội dung tóm tắt (Abstract text) ở màn hình chi tiết"
    bodyMedium:
      fontSize: 14px
      fontWeight: 400
      lineHeight: 20px
      description: "Dùng cho thông tin Metadata như Tên tạp chí, Tác giả"
    caption:
      fontSize: 12px
      fontWeight: 500
      lineHeight: 16px
      description: "Dùng cho số lượng trích dẫn (Citation count), năm xuất bản nhỏ"

rounded:
  sm: 8px                   # Bo góc cho ô nhập liệu (TextField), nhãn (Tags)
  md: 12px                  # Bo góc cho các nút bấm hành động (PrimaryButton)
  lg: 16px                  # Bo góc cho các khối Card bài báo, Card Dashboard, Khung đồ thị

spacing:
  xs: 4px                   # Khoảng cách giữa các text nhỏ liền kề (Ví dụ: Icon và số citation)
  sm: 8px                   # Khoảng cách giữa các thành phần con bên trong Card
  md: 16px                  # Khoảng cách padding tiêu chuẩn xung quanh màn hình và các Card lớn
  lg: 24px                  # Khoảng cách phân chia giữa các khối nội dung lớn độc lập
  xl: 32px                  # Khoảng cách lề trên/dưới của màn hình trống (Empty state)

components:
  searchTextField:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.secondary}"
    borderRadius: "{rounded.sm}"
    padding: 14px
    hintColor: "{colors.secondary}"
    
  primaryButton:
    backgroundColor: "#1E3A8A"
    textColor: "#FFFFFF"
    borderRadius: "{rounded.md}"
    paddingVertical: 16px
    fontWeight: 600
    
  publicationCard:
    backgroundColor: "{colors.surface}"
    borderRadius: "{rounded.lg}"
    padding: 16px
    elevation: 2
    borderWidth: 0px
    
  statCard:
    backgroundColor: "{colors.primaryLight}"
    borderRadius: "{rounded.md}"
    padding: 12px
    titleColor: "{colors.textSecondary}"
    valueColor: "{colors.primary}"
---

## 🧭 Hướng dẫn áp dụng chi tiết (Do's and Don'ts)

### 1. Nguyên tắc thiết kế chung
*   **Trực quan hóa dữ liệu (Data-focused):** App mang tính chất nghiên cứu học thuật, giao diện phải cực kỳ sạch sẽ, nền sáng (`#F8FAFC`) kết hợp thẻ trắng (`#FFFFFF`) để làm nổi bật biểu đồ xu hướng số lượng bài báo theo năm và danh sách thống kê.
*   **Đồng bộ Typography:** Không tự ý gán cứng `fontSize` hay `fontWeight` lạ trong các màn hình con. Tất cả thông tin phân tích hoặc chi tiết bài báo phải map trực tiếp theo cấu trúc Token ở trên.

### 2. Tiêu chuẩn áp dụng cho các Widget chung (Tác vụ của Người 1)
*   **Nút bấm và Ô nhập:** Toàn bộ nút "Tìm kiếm" (Search) hay ô nhập chủ đề (Topic input) phải dùng chung một kiểu bo góc `sm`/`md`[cite: 1, 2]. Không tạo thiết kế riêng lẻ cho từng màn hình[cite: 1].
*   **Hiển thị biểu đồ (`fl_chart`):** Khu vực chứa biểu đồ xu hướng theo năm phải được bọc trong một Container màu nền `surface`, bo góc `lg` và padding `md` để tạo khoảng cách an toàn với viền màn hình[cite: 1].
*   **Xử lý văn bản dài:** Đối với tên bài báo hoặc danh sách tác giả quá dài trên `PublicationCard`, thực hiện cắt chữ bằng `TextOverflow.ellipsis` tối đa 2 dòng để giữ bố cục cố định[cite: 1].

### 3. Những điều TUYỆT ĐỐI KHÔNG làm (Don'ts)
*   ❌ Không hard-code các mã màu ngẫu nhiên (như `Colors.blue`, `Colors.grey`) vào thuộc tính `color` của các Widget con[cite: 1]. Phải gọi thông qua class `AppColors`[cite: 1].
*   ❌ Không lạm dụng quá nhiều hiệu ứng đổ bóng (Elevation) cho các Card. Giữ `elevation: 2` hoặc dùng viền mờ (Border) để ứng dụng trông phẳng, thanh lịch và hiện đại[cite: 1].
*   ❌ Không gán cứng (Hard-code) khoảng cách lề. Phải sử dụng class `AppSpacing` hoặc `SizedBox` có kích thước theo token để tránh lỗi vỡ bố cục trên các kích thước màn hình Android Emulator khác nhau[cite: 1, 2].