# PRM393 - Lập trình Di động
# Lab2: Ứng dụng Di động Phân tích Xu hướng Tạp chí

## 1. Giới thiệu

Các tạp chí nghiên cứu đóng vai trò quan trọng trong việc phản ánh sự phát triển của các lĩnh vực học thuật. Việc theo dõi số lượng công bố, mức độ trích dẫn, các chủ đề nổi bật và các tác giả đóng góp trong từng tạp chí giúp người học hiểu rõ hơn về xu hướng nghiên cứu và mức độ ảnh hưởng của các nguồn xuất bản.

Trong bài tập này, sinh viên sẽ phát triển một ứng dụng di động dựa trên Flutter để truy xuất dữ liệu journal/source từ OpenAlex và cung cấp các phân tích xu hướng liên quan đến tạp chí. Ứng dụng tập trung vào việc tìm kiếm tạp chí, xem thông tin chi tiết, khám phá danh sách công bố thuộc tạp chí và trực quan hóa các xu hướng hoạt động của tạp chí theo thời gian.

## 2. Mục tiêu học tập

Sau khi hoàn thành thành công bài tập này, sinh viên sẽ có thể:

- Phát triển ứng dụng di động đa nền tảng bằng Flutter.
- Tích hợp và sử dụng RESTful API từ OpenAlex.
- Xử lý và phân tích dữ liệu JSON về journals, works, authors và topics.
- Triển khai lập trình bất đồng bộ và quản lý trạng thái.
- Thiết kế giao diện di động thân thiện với người dùng.
- Trực quan hóa dữ liệu phân tích bằng biểu đồ và bảng điều khiển.
- Áp dụng các kỹ thuật rà soát mã nguồn có hỗ trợ bởi AI để cải thiện chất lượng phần mềm.
- Tổ chức dự án phần mềm bằng kiến trúc và thực hành lập trình dễ bảo trì.

## 3. Yêu cầu bài tập

Sinh viên được yêu cầu phát triển một ứng dụng di động có tên **Journal Trend Analyzer** sử dụng OpenAlex API làm nguồn dữ liệu chính.

Ứng dụng phải cho phép người dùng tìm kiếm các tạp chí nghiên cứu, xem thông tin chi tiết của từng tạp chí và phân tích xu hướng công bố của tạp chí được chọn. Người dùng có thể tìm kiếm các journal theo tên hoặc từ khóa liên quan, ví dụ như Nature, IEEE Access, Artificial Intelligence Review, Journal of Software Engineering, hoặc bất kỳ tên tạp chí nào do người dùng nhập vào.

Tất cả dữ liệu được hiển thị trong ứng dụng phải được truy xuất động từ OpenAlex. Không được phép sử dụng các tập dữ liệu được mã hóa cứng.

### 3.1 Ngoài phạm vi

Để đảm bảo sinh viên tập trung vào phát triển ứng dụng di động, tích hợp API, trực quan hóa dữ liệu và phân tích xu hướng journal, các tính năng sau đây được loại trừ rõ ràng khỏi phạm vi của bài tập này:

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

Sinh viên phải sử dụng OpenAlex API làm nguồn dữ liệu bên ngoài duy nhất để truy xuất thông tin journal, works và dữ liệu phân tích xu hướng. Ứng dụng nên tiêu thụ dữ liệu OpenAlex trực tiếp từ client di động mà không đưa thêm các thành phần backend bổ sung.

## 4. Yêu cầu chức năng

### 4.1 Tìm kiếm tạp chí

Ứng dụng phải cho phép người dùng tìm kiếm các tạp chí nghiên cứu bằng cách nhập tên tạp chí hoặc từ khóa liên quan. Kết quả tìm kiếm chỉ nên hiển thị các OpenAlex sources có loại là `journal`.

Kết quả tìm kiếm nên hiển thị các thông tin thiết yếu của tạp chí, bao gồm tên tạp chí, loại source, nhà xuất bản hoặc tổ chức xuất bản khi có, tổng số công bố và tổng số lượt trích dẫn.

### 4.2 Chi tiết journal

Ứng dụng phải cung cấp chế độ xem chi tiết cho từng journal. Màn hình chi tiết nên bao gồm các thông tin như tên tạp chí, ISSN, publisher hoặc host organization, homepage, trạng thái open access, số lượng công bố, số lượt trích dẫn, H-index, I10-index và các thông tin thống kê liên quan khi có sẵn từ OpenAlex.

### 4.3 Danh sách công bố thuộc journal

Ứng dụng phải hiển thị danh sách các công bố thuộc journal được chọn. Mỗi công bố nên hiển thị các thông tin thiết yếu, bao gồm tiêu đề công bố, tác giả, năm công bố, số lượt trích dẫn và tên tạp chí.

Ứng dụng nên hỗ trợ phân trang, tìm kiếm trong danh sách công bố của journal, lọc theo năm, lọc theo số lượt trích dẫn tối thiểu và sắp xếp theo năm công bố hoặc số lượt trích dẫn.

### 4.4 Chi tiết công bố

Ứng dụng phải cung cấp chế độ xem chi tiết cho từng công bố. Màn hình chi tiết nên bao gồm tiêu đề công bố, tác giả, năm công bố, tên tạp chí, số lượt trích dẫn, DOI và tóm tắt khi có sẵn.

### 4.5 Phân tích xu hướng journal theo thời gian

Ứng dụng phải phân tích hoạt động của journal theo thời gian bằng cách sử dụng dữ liệu số lượng công bố theo năm. Kết quả nên được trực quan hóa bằng biểu đồ phù hợp để minh họa sự tăng trưởng hoặc suy giảm hoạt động công bố của journal được chọn.

Ứng dụng cũng nên hiển thị xu hướng trích dẫn theo năm khi dữ liệu có sẵn.

### 4.6 Chủ đề nổi bật và sự phát triển chủ đề

Ứng dụng phải xác định các chủ đề nghiên cứu nổi bật trong journal được chọn dựa trên dữ liệu topic từ OpenAlex. Kết quả nên hiển thị tên chủ đề và số lượng công bố tương ứng.

Ứng dụng nên trực quan hóa sự thay đổi của các chủ đề nổi bật theo thời gian để giúp người dùng quan sát quá trình phát triển nội dung nghiên cứu của journal.

### 4.7 Tác giả đóng góp hàng đầu trong journal

Ứng dụng phải xác định các tác giả có số lượng công bố cao nhất trong journal được chọn dựa trên dữ liệu công bố truy xuất từ OpenAlex. Kết quả nên trình bày rõ ràng tên tác giả và số lượng công bố.

### 4.8 Các công bố có ảnh hưởng trong journal

Ứng dụng phải xác định và hiển thị các công bố có ảnh hưởng nhất trong journal được chọn dựa trên số lượt trích dẫn. Các công bố nên được xếp hạng từ số lượt trích dẫn cao nhất đến thấp nhất.

### 4.9 Bảng điều khiển phân tích journal

Ứng dụng phải cung cấp một bảng điều khiển tóm tắt các thông tin chuyên sâu chính cho journal được chọn. Bảng điều khiển nên bao gồm tổng số công bố, tổng số lượt trích dẫn, số lượt trích dẫn trung bình, năm công bố hoạt động mạnh nhất, xu hướng công bố, xu hướng trích dẫn, tác giả đóng góp hàng đầu, chủ đề nổi bật và các công bố có ảnh hưởng nhất.

## 5. Yêu cầu kỹ thuật

Ứng dụng phải được phát triển bằng Flutter và Dart.

Sinh viên phải triển khai tích hợp API, truy xuất dữ liệu bất đồng bộ, xử lý JSON, xử lý lỗi, trạng thái tải, giới hạn tốc độ gọi API khi cần thiết và trực quan hóa dữ liệu. Dự án nên tuân theo một cấu trúc sạch và dễ bảo trì với sự phân tách trách nhiệm phù hợp giữa giao diện người dùng, logic nghiệp vụ và các tầng truy cập dữ liệu.

Tối thiểu, dự án nên có các module hoặc thư mục riêng cho models, services, screens, widgets và các thành phần quản lý trạng thái.

Ứng dụng phải chạy thành công trên thiết bị Android và trình giả lập Android.

## 6. Rà soát mã nguồn có hỗ trợ bởi AI

Là một phần của quy trình đảm bảo chất lượng phần mềm, sinh viên được yêu cầu thực hiện rà soát mã nguồn có hỗ trợ bởi AI trước khi nộp bài.

Sinh viên có thể sử dụng các công cụ như SonarQube, Kodus AI, CodeRabbit hoặc GitHub Copilot Code Review.

Quá trình rà soát mã nguồn phải xác định ít nhất ba vấn đề, cảnh báo, code smell, lỗi, mối quan ngại về bảo mật hoặc cơ hội cải thiện. Sinh viên nên xử lý các phát hiện khi phù hợp và ghi lại quy trình rà soát trong báo cáo dự án.

Bằng chứng về quy trình rà soát phải được cung cấp thông qua ảnh chụp màn hình và các giải thích ngắn gọn về các vấn đề được phát hiện và những cải tiến đã được triển khai.

## 7. Yêu cầu giao diện người dùng

Ứng dụng phải có ít nhất bốn màn hình chính:

- Search Screen (HOME): tìm kiếm journal.
- Journal Screen (JOURNALS): hiển thị kết quả tìm kiếm journal và cho phép mở chi tiết journal.
- Trend Analysis Screen (KEYWORDS): hiển thị phân tích xu hướng, chủ đề nổi bật và dashboard của journal được chọn.
- Profile Screen (PROFILE): cấu hình thông tin OpenAlex như email hoặc API key nếu cần.

Sinh viên có thể đưa thêm các màn hình hoặc tính năng bổ sung để nâng cao tính dễ sử dụng và trải nghiệm người dùng, ví dụ màn hình chi tiết công bố hoặc dashboard phân tích nâng cao.

Giao diện người dùng nên có tính đáp ứng, nhất quán về mặt trực quan và dễ điều hướng.
