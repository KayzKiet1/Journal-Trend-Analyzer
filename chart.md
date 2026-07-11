# Chart Coverage Check

Nguồn đối chiếu: Google Sheet `PaperTrend Analysis`.

Kết luận: app hiện đã có **5 chart khớp rõ ràng và có thể thao tác để xem trong UI**, nên **vừa đủ yêu cầu ít nhất 5 chart**.

| Có trong app | No trong sheet | Chart name trong sheet | Display Type trong sheet | Vị trí trong app | Thao tác để thấy chart |
| --- | ---: | --- | --- | --- | --- |
| Có | 1 | Publication Trend | Line Chart | HOME topic overview, Journal Detail, Keyword Detail | Vào `HOME` -> nhập topic ví dụ `artificial intelligence` hoặc `military` -> tick topic gợi ý -> bấm search. Chart nằm trong phần `TOPIC RESEARCH OVERVIEW`. Hoặc vào `KEYWORDS` -> chọn một keyword -> xem `Publication trend over time`. |
| Có | 2 | Citation Trend | Line Chart | Journal Trends / Compare Journals | Vào `JOURNALS` sau khi đã search topic ở HOME -> chọn 2 journal bằng nút compare -> bấm `Compare` -> xem phần `CITATION TREND`. |
| Có | 3 | Top Keywords | Horizontal Bar | KEYWORDS tab - Most used keywords | Vào `HOME` -> search và tick topic -> sang tab `KEYWORDS` -> xem chart `Most used keywords`. |
| Có | 7 | Author Impact | Horizontal Bar | Keyword Detail - Top authors; Journal Trends - Author Impact | Vào `KEYWORDS` sau khi đã có kết quả từ HOME -> bấm một keyword trong `KEYWORD OCCURRENCES` -> xem chart `Top authors`. |
| Có | 14 | Journal Ranking | Horizontal Bar | JOURNALS tab - Top journals by publications; Keyword Detail - Related journals | Vào `HOME` -> search topic -> sang tab `JOURNALS` -> xem chart `Top journals by publications`. |

## Chart Có Một Phần Nhưng Chưa Khớp Hoàn Toàn

| Trạng thái | No trong sheet | Chart name trong sheet | Display Type trong sheet | Ghi chú |
| --- | ---: | --- | --- | --- |
| Có một phần | 4 | Emerging Keywords | Line Chart | App có `Recently active keywords` trong tab `KEYWORDS` và keyword trend theo thời gian khi bấm vào keyword, nhưng phần recently active đang hiển thị bằng Horizontal Bar, chưa đúng hoàn toàn với Line Chart tăng trưởng nhanh nhất. |

## Chart Có Trong Code Nhưng Hiện Không Có Đường Thao Tác Từ UI

| Trạng thái | No trong sheet | Chart name trong sheet | Display Type trong sheet | Ghi chú |
| --- | ---: | --- | --- | --- |
| Không tính | 5 | Topic Evolution | Area Chart | Code có `TopicEvolutionChart`, nhưng hiện nằm trong nhánh journal dashboard cũ và không có đường thao tác từ UI. Ngoài ra display type đang là Line Chart nhiều đường, chưa phải Area Chart. |
| Không tính | 24 | Author-Topic Matrix | Heatmap | Code có `AuthorTopicHeatmap`, nhưng hiện nằm trong nhánh journal dashboard cũ và không có đường thao tác từ UI sau khi bỏ nút chuyển nhầm sang tab KEYWORDS. Vì vậy không tính là chart đang có trong app UI. |

## Chart Ngoài Danh Sách Hoặc Không Khớp Tên Sheet

- `Journal contribution` trong JOURNALS tab dùng Donut Chart, nhưng không phải `Quartile Distribution` No 16 trong sheet.
- `Citations by journal` dùng Horizontal Bar, hữu ích cho yêu cầu journal analysis nhưng không khớp trực tiếp với một chart No cụ thể trong sheet.

## Tổng Kết

- Tổng chart khớp rõ ràng và thao tác thấy được trong UI: **5**
- Yêu cầu tối thiểu: **5**
- Trạng thái: **Đạt**
