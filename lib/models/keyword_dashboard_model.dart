class KeywordCandidate {
  final String id;
  final String name;
  final int totalCount;

  const KeywordCandidate({
    required this.id,
    required this.name,
    required this.totalCount,
  });
}

class KeywordGrowthData {
  final String id;
  final String name;
  final int totalCount;
  final int startYear;
  final int startCount;
  final int endYear;
  final int endCount;
  final double growthRate;

  const KeywordGrowthData({
    required this.id,
    required this.name,
    required this.totalCount,
    required this.startYear,
    required this.startCount,
    required this.endYear,
    required this.endCount,
    required this.growthRate,
  });
}
