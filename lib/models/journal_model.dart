/// Lớp đại diện cho nguồn xuất bản (Source/Journal entity trong OpenAlex)
class Journal {
  final String id;
  final String name;
  final String? type;
  final String? publisher;
  final int worksCount;
  final int citedByCount;

  // New fields for detailed view
  final String? homepageUrl;
  final List<String> issns;
  final List<String> alternateNames;
  final bool isOa;
  final bool isInDoaj;
  final int? apcUsd;
  final int? hIndex;
  final int? i10Index;
  final double? twoYearMeanCitedness;
  final List<JournalYearlyData> countsByYear;

  Journal({
    required this.id,
    required this.name,
    this.type,
    this.publisher,
    this.worksCount = 0,
    this.citedByCount = 0,
    this.homepageUrl,
    this.issns = const [],
    this.alternateNames = const [],
    this.isOa = false,
    this.isInDoaj = false,
    this.apcUsd,
    this.hIndex,
    this.i10Index,
    this.twoYearMeanCitedness,
    this.countsByYear = const [],
  });

  /// Chuyển đổi từ dữ liệu JSON của OpenAlex sang đối tượng Journal
  factory Journal.fromJson(Map<String, dynamic> json) {
    // Xử lý cả trường hợp source nằm trong location hoặc là entity độc lập
    final Map<String, dynamic> sourceData = json.containsKey('source')
        ? json['source']
        : json;

    final List<JournalYearlyData> yearlyData =
        (json['counts_by_year'] as List?)
            ?.map((e) => JournalYearlyData.fromJson(e))
            .toList() ??
        [];

    return Journal(
      id: sourceData['id'] ?? '',
      name: sourceData['display_name'] ?? 'Unknown Source',
      type: sourceData['type'],
      publisher: sourceData['publisher'] ?? json['host_organization_name'],
      worksCount: json['works_count'] ?? 0,
      citedByCount: json['cited_by_count'] ?? 0,
      homepageUrl: sourceData['homepage_url'],
      issns:
          (sourceData['issn'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      alternateNames:
          (sourceData['alternate_titles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isOa: sourceData['is_oa'] ?? false,
      isInDoaj: sourceData['is_in_doaj'] ?? false,
      apcUsd: sourceData['apc_usd'],
      hIndex: json['summary_stats']?['h_index'],
      i10Index: json['summary_stats']?['i10_index'],
      twoYearMeanCitedness:
          (json['summary_stats']?['2yr_mean_citedness'] as num?)?.toDouble(),
      countsByYear: yearlyData,
    );
  }

  factory Journal.fromStoredJson(Map<String, dynamic> json) {
    return Journal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Source',
      type: json['type']?.toString(),
      publisher: json['publisher']?.toString(),
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      homepageUrl: json['homepage_url']?.toString(),
      issns: (json['issns'] as List?)?.map((e) => e.toString()).toList() ?? [],
      alternateNames:
          (json['alternate_names'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isOa: json['is_oa'] as bool? ?? false,
      isInDoaj: json['is_in_doaj'] as bool? ?? false,
      apcUsd: json['apc_usd'] as int?,
      hIndex: json['h_index'] as int?,
      i10Index: json['i10_index'] as int?,
      twoYearMeanCitedness: (json['two_year_mean_citedness'] as num?)
          ?.toDouble(),
      countsByYear:
          (json['counts_by_year'] as List?)
              ?.map((e) => JournalYearlyData.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toStoredJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'publisher': publisher,
      'works_count': worksCount,
      'cited_by_count': citedByCount,
      'homepage_url': homepageUrl,
      'issns': issns,
      'alternate_names': alternateNames,
      'is_oa': isOa,
      'is_in_doaj': isInDoaj,
      'apc_usd': apcUsd,
      'h_index': hIndex,
      'i10_index': i10Index,
      'two_year_mean_citedness': twoYearMeanCitedness,
      'counts_by_year': countsByYear.map((e) => e.toJson()).toList(),
    };
  }
}

class JournalYearlyData {
  final int year;
  final int worksCount;
  final int citedByCount;

  JournalYearlyData({
    required this.year,
    required this.worksCount,
    required this.citedByCount,
  });

  factory JournalYearlyData.fromJson(Map<String, dynamic> json) {
    return JournalYearlyData(
      year: json['year'] ?? 0,
      worksCount: json['works_count'] ?? 0,
      citedByCount: json['cited_by_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'works_count': worksCount,
      'cited_by_count': citedByCount,
    };
  }
}
