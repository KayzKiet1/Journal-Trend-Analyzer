/// OpenAlex API configuration and shared request defaults.
class ApiConstants {
  ApiConstants._();

  static const String openAlexBaseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '$openAlexBaseUrl/works';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const int defaultPerPage = 25;
}
