/// Các hằng số liên quan đến API OpenAlex
class ApiConstants {
  /// URL cơ sở của API OpenAlex
  static const String baseUrl = 'https://api.openalex.org';

  /// Endpoint cho các bài báo (works)
  static const String worksEndpoint = '/works';

  /// Email liên hệ (để OpenAlex ưu tiên trong hàng đợi - "polite pool")
  static const String contactEmail =
      'prm_student@example.com'; // Thay bằng email thực tế nếu cần

  /// API Key của OpenAlex (nếu có, giúp tăng giới hạn và tốc độ gọi API)
  /// Đăng ký miễn phí tại: https://openalex.org/settings/api
  static const String apiKey = '';

  /// Số lần thử lại tối đa khi gặp lỗi rate limit
  static const int maxRetries = 3;

  /// Khoảng cách tối thiểu giữa 2 request OpenAlex trong toàn app.
  /// Keeps app traffic below conservative public limits while reducing wait time.
  static const int minRequestIntervalMs = 350;

  /// Timeout cho mỗi request để app không treo quá lâu khi mạng yếu.
  static const int requestTimeoutSeconds = 20;

  /// Giới hạn thời gian chờ tối đa giữa các lần retry.
  static const int maxRetryDelaySeconds = 30;

  /// Thời gian cache mặc định (phút)
  static const int defaultCacheMinutes = 15;
}
