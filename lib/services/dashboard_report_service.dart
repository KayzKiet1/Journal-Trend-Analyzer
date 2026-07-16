import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/journal_model.dart';
import '../models/keyword_dashboard_model.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../utils/analysis_helper.dart';

class DashboardReportService {
  Future<Uint8List> buildResearchTrendReport({
    required String topic,
    required String exportedBy,
    required int totalPublications,
    required double averageCitations,
    required int? peakYear,
    required Map<String, int> topAuthors,
    required Map<String, int> topJournals,
    required List<TrendData> publicationTrends,
    required List<Publication> influentialPublications,
    List<Map<String, dynamic>> topKeywords = const [],
    List<KeywordGrowthData> keywordGrowth = const [],
  }) async {
    final document = pw.Document();
    final generatedAt = DateTime.now().toLocal();
    final topPublication = influentialPublications.isEmpty
        ? null
        : influentialPublications.first;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Journal Trend Analyzer - Research Trend Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Generated at: $generatedAt'),
          pw.Text(
            'Exported by: ${exportedBy.isEmpty ? 'Unknown user' : exportedBy}',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Research Scope'),
          _keyValueTable([
            ['Selected topics', topic.isEmpty ? 'N/A' : topic],
            ['Data source', 'OpenAlex'],
            ['Publication type', 'Journal publications'],
            [
              'Method note',
              'This report uses the dashboard analytics already loaded in the app.',
            ],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Executive Summary'),
          _keyValueTable([
            ['Total publications', totalPublications.toString()],
            ['Average citations', averageCitations.toStringAsFixed(1)],
            ['Peak publication year', peakYear?.toString() ?? 'N/A'],
            ['Top author', _firstEntryLabel(topAuthors)],
            ['Top journal', _firstEntryLabel(topJournals)],
            ['Most influential publication', topPublication?.title ?? 'N/A'],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Publication Trend Over Time'),
          _trendTable(
            headers: ['Year', 'Publications'],
            rows: publicationTrends
                .map((trend) => [trend.year.toString(), trend.count.toString()])
                .toList(),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Journals'),
          _simpleRankTable(
            topJournals.entries
                .map((entry) => [entry.key, entry.value.toString()])
                .toList(),
            secondHeader: 'Publications',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Authors'),
          _simpleRankTable(
            topAuthors.entries
                .map((entry) => [entry.key, entry.value.toString()])
                .toList(),
            secondHeader: 'Publications',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Most Influential Publications'),
          _paperTable(influentialPublications.take(8).toList()),
          pw.SizedBox(height: 18),
          _sectionTitle('Keywords Dashboard'),
          if (topKeywords.isEmpty && keywordGrowth.isEmpty)
            pw.Text(
              'No Keywords dashboard data was loaded when this report was exported.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else ...[
            _keywordTable(topKeywords.take(8).toList()),
            if (keywordGrowth.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _keywordGrowthTable(keywordGrowth.take(8).toList()),
            ],
          ],
          pw.SizedBox(height: 18),
          _sectionTitle('Notes'),
          pw.Text(
            'OpenAlex data can change over time as records are updated. '
            'The numbers in this PDF reflect the dashboard state at export time.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildKeywordsReport({
    required Journal journal,
    required List<Publication> publications,
    required Map<String, List<TrendData>> topicEvolution,
  }) async {
    final document = pw.Document();
    final topPapers = AnalysisHelper.getTopCitedPapers(publications, limit: 5);
    final topAuthors = AnalysisHelper.getTopAuthors(publications);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Journal Trend Analyzer - Keyword Trends Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated at: ${DateTime.now().toLocal()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Journal Overview'),
          _keyValueTable([
            ['Journal', journal.name],
            ['Publisher', journal.publisher ?? 'N/A'],
            ['Type', journal.type ?? 'N/A'],
            ['Publications', journal.worksCount.toString()],
            ['Cited by count', journal.citedByCount.toString()],
            ['H-index', journal.hIndex?.toString() ?? 'N/A'],
            ['I10-index', journal.i10Index?.toString() ?? 'N/A'],
          ]),
          pw.SizedBox(height: 18),
          _sectionTitle('Publication Trend'),
          _trendTable(
            headers: ['Year', 'Publications', 'Citations'],
            rows: journal.countsByYear
                .map(
                  (yearData) => [
                    yearData.year.toString(),
                    yearData.worksCount.toString(),
                    yearData.citedByCount.toString(),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Authors'),
          _simpleRankTable(
            topAuthors.entries
                .map((entry) => [entry.key, entry.value.toString()])
                .toList(),
            secondHeader: 'Publications',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Influential Papers'),
          _paperTable(topPapers),
          pw.SizedBox(height: 18),
          _sectionTitle('Topic Evolution'),
          _topicEvolutionTable(topicEvolution),
        ],
      ),
    );

    return document.save();
  }

  String _firstEntryLabel(Map<String, int> data) {
    if (data.isEmpty) return 'N/A';
    final entry = data.entries.first;
    return '${entry.key} (${entry.value})';
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _keyValueTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: ['Metric', 'Value'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _trendTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final sortedRows = List<List<String>>.from(rows)
      ..sort((a, b) => b.first.compareTo(a.first));

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: sortedRows.take(10).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _simpleRankTable(
    List<List<String>> rows, {
    required String secondHeader,
  }) {
    if (rows.isEmpty) {
      return pw.Text(
        'No data available.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Name', secondHeader],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _paperTable(List<Publication> papers) {
    if (papers.isEmpty) {
      return pw.Text(
        'No paper data available.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Title', 'Year', 'Citations'],
      data: papers
          .map(
            (paper) => [
              paper.title,
              paper.publicationYear.toString(),
              paper.citedByCount.toString(),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _keywordTable(List<Map<String, dynamic>> keywords) {
    if (keywords.isEmpty) {
      return pw.Text(
        'No top keyword data available.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Keyword', 'Matching works'],
      data: keywords
          .map(
            (keyword) => [
              keyword['name']?.toString() ?? 'Unknown keyword',
              ((keyword['count'] as num?)?.toInt() ?? 0).toString(),
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _keywordGrowthTable(List<KeywordGrowthData> growthRows) {
    return pw.TableHelper.fromTextArray(
      headers: ['Trending keyword', 'Year range', 'Growth'],
      data: growthRows
          .map(
            (growth) => [
              growth.name,
              '${growth.startYear}-${growth.endYear}',
              '${growth.growthRate.toStringAsFixed(1)}%',
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }

  pw.Widget _topicEvolutionTable(Map<String, List<TrendData>> topicEvolution) {
    if (topicEvolution.isEmpty) {
      return pw.Text(
        'No topic evolution data available.',
        style: const pw.TextStyle(fontSize: 10),
      );
    }

    final rows = topicEvolution.entries.map((entry) {
      final total = entry.value.fold<int>(0, (sum, trend) => sum + trend.count);
      final years = entry.value.map((trend) => trend.year).toList()..sort();
      final range = years.isEmpty ? 'N/A' : '${years.first}-${years.last}';
      return [entry.key, range, total.toString()];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Topic', 'Year range', 'Total count'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
    );
  }
}
