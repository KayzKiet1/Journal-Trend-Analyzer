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
      throw const UrlOpenException('Invalid file URL.');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const UrlOpenException('Could not open file URL.');
    }
  }
}
