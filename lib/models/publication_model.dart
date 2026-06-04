class Publication {
  final String title;
  final int year;
  final int citations;
  final String journal;
  final List<String> authors;
  final String doi;
  final String abstractText;

  Publication({
    required this.title,
    required this.year,
    required this.citations,
    required this.journal,
    required this.authors,
    required this.doi,
    required this.abstractText,
  });
}