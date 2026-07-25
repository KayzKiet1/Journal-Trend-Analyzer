import 'package:url_launcher/url_launcher.dart';

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

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened) {
      throw const UrlOpenException('Không thể mở link file.');
    }
  }
}
