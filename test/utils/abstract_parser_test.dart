import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/abstract_parser.dart';

void main() {
  group('AbstractParser Tests', () {
    test('parseInvertedIndex returns correctly parsed string', () {
      final invertedIndex = {
        'The': [0],
        'quick': [1],
        'brown': [2],
        'fox': [3],
      };
      final result = AbstractParser.parseInvertedIndex(invertedIndex);
      expect(result, 'The quick brown fox');
    });

    test('parseInvertedIndex handles out of order positions', () {
      final invertedIndex = {
        'fox': [3],
        'brown': [2],
        'The': [0],
        'quick': [1],
      };
      final result = AbstractParser.parseInvertedIndex(invertedIndex);
      expect(result, 'The quick brown fox');
    });

    test('parseInvertedIndex handles multiple positions for same word', () {
      final invertedIndex = {
        'to': [0, 2],
        'be': [1, 3],
      };
      final result = AbstractParser.parseInvertedIndex(invertedIndex);
      expect(result, 'to be to be');
    });

    test('parseInvertedIndex returns fallback message for null input', () {
      expect(AbstractParser.parseInvertedIndex(null), 'No abstract available.');
    });

    test('parseInvertedIndex returns fallback message for empty input', () {
      expect(AbstractParser.parseInvertedIndex({}), 'No abstract available.');
    });

    test('parseInvertedIndex handles non-int positions gracefully', () {
      final invertedIndex = {
        'word': ['not_an_int', 0],
      };
      final result = AbstractParser.parseInvertedIndex(invertedIndex);
      expect(result, 'word');
    });
    
    test('parseInvertedIndex handles gaps in positions', () {
        final invertedIndex = {
            'A': [0],
            'C': [2],
        };
        final result = AbstractParser.parseInvertedIndex(invertedIndex);
        expect(result, 'A C');
    });
  });
}
