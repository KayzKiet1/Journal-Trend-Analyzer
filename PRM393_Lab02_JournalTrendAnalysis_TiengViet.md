# PRM393 – Lập trình Di động
# Lab2: Ứng dụng Di động Phân tích Xu hướng Tạp chí

## 1. Giới thiệu

Các công bố nghiên cứu đang tăng nhanh trong nhiều lĩnh vực, khiến việc xác định các chủ đề mới nổi, các bài báo có ảnh hưởng, các nhà nghiên cứu tích cực và các xu hướng công bố ngày càng trở nên quan trọng. Các cơ sở dữ liệu học thuật như OpenAlex cung cấp quyền truy cập vào dữ liệu học thuật quy mô lớn có thể được sử dụng cho phân tích nghiên cứu và hỗ trợ ra quyết định.

Trong bài tập này, sinh viên sẽ phát triển một ứng dụng di động dựa trên Flutter để truy xuất dữ liệu công bố từ OpenAlex và cung cấp các thông tin phân tích chuyên sâu thông qua các trực quan hóa và bảng điều khiển tương tác. Ứng dụng nên giúp người dùng khám phá xu hướng nghiên cứu cho một chủ đề được chọn và hiểu rõ hơn về bối cảnh nghiên cứu tương ứng.

## 2. Mục tiêu học tập

Sau khi hoàn thành thành công bài tập này, sinh viên sẽ có thể:

- Phát triển các ứng dụng di động đa nền tảng bằng Flutter.
- Tích hợp và sử dụng các RESTful API.
- Xử lý và phân tích dữ liệu JSON từ các nguồn bên ngoài.
- Triển khai lập trình bất đồng bộ và quản lý trạng thái.
- Thiết kế giao diện di động thân thiện với người dùng.
- Trực quan hóa dữ liệu phân tích bằng biểu đồ và bảng điều khiển.
- Áp dụng các kỹ thuật rà soát mã nguồn có hỗ trợ bởi AI để cải thiện chất lượng phần mềm.
- Tổ chức dự án phần mềm bằng kiến trúc và thực hành lập trình dễ bảo trì.

## 3. Yêu cầu bài tập

Sinh viên được yêu cầu phát triển một ứng dụng di động có tên **Journal Trend Analyzer** sử dụng OpenAlex API làm nguồn dữ liệu chính.

Ứng dụng phải cho phép người dùng tìm kiếm một chủ đề nghiên cứu và phân tích dữ liệu công bố được truy xuất. Các chủ đề có thể bao gồm Artificial Intelligence, Software Engineering, Data Science, Cybersecurity, Internet of Things, Blockchain, hoặc bất kỳ chủ đề nào do người dùng nhập vào.

Tất cả dữ liệu được hiển thị trong ứng dụng phải được truy xuất động từ OpenAlex. Không được phép sử dụng các tập dữ liệu được mã hóa cứng.

### 3.1 Ngoài phạm vi

Để đảm bảo sinh viên tập trung vào phát triển ứng dụng di động, tích hợp API, trực quan hóa dữ liệu và phân tích xu hướng, các tính năng sau đây được loại trừ rõ ràng khỏi phạm vi của bài tập này:

- Phát triển các dịch vụ backend hoặc REST API tùy chỉnh.
- Triển khai các cơ chế xác thực hoặc phân quyền người dùng.
- Đăng ký người dùng, đăng nhập, quản lý mật khẩu hoặc kiểm soát truy cập dựa trên vai trò.
- Thiết kế và triển khai cơ sở dữ liệu.
- Lưu trữ dữ liệu trên các nền tảng đám mây.
- Đồng bộ hóa dữ liệu thời gian thực.
- Thông báo đẩy.
- Các tính năng xử lý thanh toán.
- Các tính năng mạng xã hội như bình luận, thích hoặc chia sẻ.
- Bảng điều khiển quản trị.
- Huấn luyện hoặc triển khai mô hình học máy.
- Phát triển ứng dụng web.

Sinh viên phải sử dụng OpenAlex API làm nguồn dữ liệu bên ngoài duy nhất để truy xuất thông tin công bố và thực hiện phân tích xu hướng. Ứng dụng nên tiêu thụ dữ liệu OpenAlex trực tiếp từ client di động mà không đưa thêm các thành phần backend bổ sung.

## 4. Yêu cầu chức năng

### 4.1 Tìm kiếm chủ đề

Ứng dụng phải cho phép người dùng tìm kiếm các công bố nghiên cứu bằng cách nhập một từ khóa chủ đề. Kết quả tìm kiếm nên hiển thị các thông tin công bố thiết yếu, bao gồm tiêu đề công bố, năm công bố, số lượt trích dẫn và tên tạp chí.

### 4.2 Chi tiết công bố

Ứng dụng phải cung cấp chế độ xem chi tiết cho từng công bố. Màn hình chi tiết nên bao gồm các thông tin như tiêu đề công bố, tác giả, năm công bố, tên tạp chí, số lượt trích dẫn, DOI và tóm tắt khi có sẵn.

### 4.3 Phân tích xu hướng công bố

Ứng dụng phải phân tích hoạt động công bố theo thời gian bằng cách nhóm các công bố theo năm công bố. Kết quả nên được trực quan hóa bằng một biểu đồ phù hợp để minh họa sự tăng trưởng hoặc suy giảm của chủ đề nghiên cứu được chọn.

### 4.4 Các bài báo có ảnh hưởng hàng đầu

Ứng dụng phải xác định và hiển thị các công bố có ảnh hưởng nhất dựa trên số lượt trích dẫn. Các công bố nên được xếp hạng từ số lượt trích dẫn cao nhất đến thấp nhất.

### 4.5 Các tạp chí nghiên cứu hàng đầu

Ứng dụng phải xác định các tạp chí đóng góp số lượng công bố lớn nhất liên quan đến chủ đề nghiên cứu được chọn. Kết quả nên được trình bày bằng danh sách xếp hạng hoặc biểu đồ.

### 4.6 Các tác giả đóng góp hàng đầu

Ứng dụng phải xác định các tác giả đã công bố số lượng bài báo cao nhất liên quan đến chủ đề nghiên cứu được chọn. Kết quả nên trình bày rõ ràng tên tác giả và số lượng công bố.

### 4.7 Bảng điều khiển xu hướng nghiên cứu

Ứng dụng phải cung cấp một bảng điều khiển tóm tắt các thông tin chuyên sâu chính cho chủ đề được chọn. Bảng điều khiển nên bao gồm tổng số công bố, số lượt trích dẫn trung bình, năm công bố hoạt động mạnh nhất, tạp chí hàng đầu, tác giả hàng đầu và bài báo có ảnh hưởng nhất.

## 5. Yêu cầu kỹ thuật

Ứng dụng phải được phát triển bằng Flutter và Dart.

Sinh viên phải triển khai tích hợp API, truy xuất dữ liệu bất đồng bộ, xử lý JSON, xử lý lỗi, trạng thái tải và trực quan hóa dữ liệu. Dự án nên tuân theo một cấu trúc sạch và dễ bảo trì với sự phân tách trách nhiệm phù hợp giữa giao diện người dùng, logic nghiệp vụ và các tầng truy cập dữ liệu.

Tối thiểu, dự án nên có các module hoặc thư mục riêng cho models, services, screens, widgets và các thành phần quản lý trạng thái.

Ứng dụng phải chạy thành công trên thiết bị Android và trình giả lập Android.

## 6. Rà soát mã nguồn có hỗ trợ bởi AI

Là một phần của quy trình đảm bảo chất lượng phần mềm, sinh viên được yêu cầu thực hiện rà soát mã nguồn có hỗ trợ bởi AI trước khi nộp bài.

Sinh viên có thể sử dụng các công cụ như SonarQube, Kodus AI, CodeRabbit hoặc GitHub Copilot Code Review.

Quá trình rà soát mã nguồn phải xác định ít nhất ba vấn đề, cảnh báo, code smell, lỗi, mối quan ngại về bảo mật hoặc cơ hội cải thiện. Sinh viên nên xử lý các phát hiện khi phù hợp và ghi lại quy trình rà soát trong báo cáo dự án.

Bằng chứng về quy trình rà soát phải được cung cấp thông qua ảnh chụp màn hình và các giải thích ngắn gọn về các vấn đề được phát hiện và những cải tiến đã được triển khai.

## 7. Yêu cầu giao diện người dùng

Ứng dụng phải có ít nhất bốn màn hình chính:

- Search Screen
- Publication Detail Screen
- Trend Analysis Screen
- Research Dashboard Screen

Sinh viên có thể đưa thêm các màn hình hoặc tính năng bổ sung để nâng cao tính dễ sử dụng và trải nghiệm người dùng.

Giao diện người dùng nên có tính đáp ứng, nhất quán về mặt trực quan và dễ điều hướng.

## 8. Sản phẩm bàn giao

### 8.1 Mã nguồn

Sinh viên phải nộp toàn bộ mã nguồn thông qua một kho lưu trữ GitHub được đặt tên theo quy ước sau:

```text
PRM393_Lab2_StudentID
```

Kho lưu trữ phải chứa tất cả các tệp mã nguồn và bất kỳ tài nguyên bổ sung nào cần thiết để chạy ứng dụng.

### 8.2 Báo cáo dự án

Sinh viên phải nộp một báo cáo dự án khoảng 5–10 trang ở định dạng PDF.

Báo cáo nên bao gồm tổng quan dự án, thiết kế hệ thống, chi tiết triển khai, cách tiếp cận tích hợp API, ảnh chụp màn hình các tính năng chính, kết quả phân tích xu hướng, các phát hiện từ rà soát mã nguồn có hỗ trợ bởi AI, các thách thức gặp phải và bài học rút ra.

### 8.3 Video trình diễn

Sinh viên phải nộp một video trình diễn có thời lượng khoảng 5–10 phút.

Video nên trình diễn các tính năng đã triển khai, bao gồm tìm kiếm chủ đề, chi tiết công bố, phân tích xu hướng công bố, các tạp chí hàng đầu, các tác giả hàng đầu, phân tích trên bảng điều khiển và quy trình rà soát mã nguồn có hỗ trợ bởi AI.
