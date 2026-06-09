# System Detail – PRM393 Lab2: Journal Trend Analyzer

## 1. Dự án này đang làm gì?

Dự án **PRM393 – Lab2: Journal Trend Analyzer** là một **ứng dụng mobile bằng Flutter** dùng để phân tích xu hướng bài báo khoa học theo một chủ đề người dùng nhập vào.

Ví dụ người dùng nhập:

> Artificial Intelligence  
> Software Engineering  
> Data Science  
> Cybersecurity  
> Blockchain

Ứng dụng sẽ gọi dữ liệu trực tiếp từ **OpenAlex API**, sau đó hiển thị danh sách bài báo và phân tích dữ liệu như:

- Số lượng bài báo theo năm.
- Bài báo có nhiều trích dẫn nhất.
- Tạp chí xuất bản nhiều bài nhất.
- Tác giả đóng góp nhiều nhất.
- Dashboard tổng quan.

OpenAlex cung cấp dữ liệu học thuật dạng **Works**, tức là các tài liệu học thuật như journal articles, books, datasets, theses. API `/works` hỗ trợ tìm kiếm theo từ khóa, sắp xếp theo citation count, publication date, relevance score, và có thể group theo `publication_year`.

---

## 2. Hiểu đơn giản luồng app

Luồng chính của app sẽ như sau:

```text
Người dùng nhập topic
→ App gọi OpenAlex API
→ App nhận JSON data
→ App xử lý dữ liệu
→ Hiển thị danh sách publication
→ Người dùng bấm vào 1 bài để xem chi tiết
→ App phân tích trend, top paper, top journal, top author
→ Hiển thị dashboard tổng quan
```

Ví dụ topic: **Artificial Intelligence**

App sẽ hiển thị:

| Chức năng | Nội dung |
|---|---|
| Search Screen | Danh sách bài báo về Artificial Intelligence |
| Publication Detail | Chi tiết bài báo: title, authors, year, journal, citation, DOI, abstract |
| Trend Analysis | Biểu đồ số lượng bài báo theo năm |
| Top Influential Papers | Các bài có citation cao nhất |
| Top Research Journals | Tạp chí xuất bản nhiều bài nhất |
| Top Authors | Tác giả có nhiều bài nhất |
| Dashboard | Tổng bài báo, citation trung bình, năm hoạt động mạnh nhất, top journal, top author |

---

## 3. Những gì KHÔNG cần làm

Theo yêu cầu giảng viên, bài này **không cần**:

- Không cần Backend API.
- Không cần Spring Boot / Node.js / REST API tự viết.
- Không cần database.
- Không cần login/register.
- Không cần phân quyền.
- Không cần web app.
- Không cần realtime.
- Không cần cloud.
- Không cần machine learning.

Chỉ cần làm **Flutter mobile app chạy được trên Android device/emulator** và lấy dữ liệu trực tiếp từ OpenAlex.

---

## 4. Công nghệ nên dùng

| Thành phần | Gợi ý |
|---|---|
| Mobile framework | Flutter + Dart |
| API call | `http` package hoặc `dio` |
| State management | Provider, Riverpod hoặc Bloc |
| Chart | `fl_chart` |
| Data source | OpenAlex API |
| Platform cần chạy | Android device / Android emulator |
| Code review AI | GitHub Copilot Review, CodeRabbit, SonarQube hoặc Kodus AI |

OpenAlex `/works` có thể dùng:

- `search` để tìm bài theo chủ đề.
- `sort` để sắp xếp theo citation, publication date hoặc relevance score.
- `group_by` để nhóm dữ liệu như `publication_year`.
- `select` để chỉ lấy các field cần thiết nhằm giảm dung lượng response.

---

## 5. Các dữ liệu cần lấy từ OpenAlex

Một publication nên map thành model như sau:

| Field trong app | Dữ liệu OpenAlex tương ứng |
|---|---|
| Title | `display_name` |
| Publication Year | `publication_year` |
| Citation Count | `cited_by_count` |
| Journal Name | `primary_location.source.display_name` |
| Authors | `authorships.author.display_name` |
| DOI | `doi` |
| Abstract | `abstract_inverted_index` |
| Publication Date | `publication_date` |

Lưu ý: abstract trong OpenAlex thường không phải text trực tiếp mà có thể ở dạng `abstract_inverted_index`, nên nhóm cần viết hàm chuyển nó thành đoạn văn bình thường.

---

## 6. Tóm tắt ngắn gọn

Dự án này là một **ứng dụng Flutter mobile** giúp người dùng nhập chủ đề nghiên cứu, lấy dữ liệu bài báo từ **OpenAlex API**, sau đó phân tích và trực quan hóa xu hướng nghiên cứu thông qua danh sách bài báo, màn hình chi tiết, biểu đồ trend, top journals, top authors, top influential papers và dashboard tổng quan.