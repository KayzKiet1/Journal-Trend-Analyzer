import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/keyword_formatters.dart';

void main() {
  group('keywordId', () {
    test('extracts the last path segment from an OpenAlex URL', () {
      expect(keywordId('https://openalex.org/keywords/K123'), 'K123');
      expect(keywordId('https://openalex.org/K456'), 'K456');
    });

    test('returns the last slash-separated segment for non-URL values', () {
      expect(keywordId('keywords/K789'), 'K789');
      expect(keywordId('plain-keyword-id'), 'plain-keyword-id');
    });

    test('handles trailing slash and empty input consistently', () {
      expect(keywordId('https://openalex.org/keywords/K123/'), '');
      expect(keywordId(''), '');
    });
  });
}
