/// Các hằng số liên quan đến API OpenAlex
class ApiConstants {
  /// URL cơ sở của API OpenAlex
  static const String baseUrl = 'https://api.openalex.org';
  
  /// Endpoint cho các bài báo (works)
  static const String worksEndpoint = '/works';
  
  /// Email liên hệ (để OpenAlex ưu tiên trong hàng đợi - "polite pool")
  static const String contactEmail = 'prm_student@example.com'; // Thay bằng email thực tế nếu cần
}
