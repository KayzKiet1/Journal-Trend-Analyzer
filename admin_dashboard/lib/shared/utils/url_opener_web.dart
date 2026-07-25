import 'package:web/web.dart' as web;

class UrlOpenException implements Exception {
  const UrlOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UrlOpener {
  const UrlOpener();

  Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw const UrlOpenException('Link file không hợp lệ.');
    }

    final window = web.window.open(url, '_blank');
    if (window == null || window.closed) {
      throw const UrlOpenException(
        'Trình duyệt đã chặn tab mới. Hãy cho phép popup hoặc sao chép link.',
      );
    }
  }
}
