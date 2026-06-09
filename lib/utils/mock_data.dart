import 'package:journal_trend_analyzer/models/author_model.dart';
import 'package:journal_trend_analyzer/models/publication_model.dart';

/// Static sample publications for UI development and offline previews.
class MockData {
  MockData._();

  static final List<Publication> samplePublications = [
    Publication(
      id: 'https://openalex.org/Wmock001',
      title: 'Deep Learning for Scientific Trend Analysis',
      publicationYear: 2023,
      publicationDate: '2023-06-15',
      citedByCount: 842,
      journalName: 'Journal of Machine Learning Research',
      authors: [
        Author(id: 'https://openalex.org/Amock001', name: 'Alice Nguyen'),
        Author(id: 'https://openalex.org/Amock002', name: 'Brian Chen'),
      ],
      doi: '10.1234/jmlr.2023.001',
      abstractText:
          'This paper surveys deep learning methods for analyzing publication '
          'trends across scientific domains using large-scale bibliographic data.',
    ),
    Publication(
      id: 'https://openalex.org/Wmock002',
      title: 'A Survey of Artificial Intelligence in Healthcare',
      publicationYear: 2022,
      publicationDate: '2022-11-03',
      citedByCount: 615,
      journalName: 'Nature Medicine',
      authors: [
        Author(id: 'https://openalex.org/Amock003', name: 'Carlos Rivera'),
        Author(id: 'https://openalex.org/Amock004', name: 'Diana Patel'),
        Author(id: 'https://openalex.org/Amock005', name: 'Elena Kowalski'),
      ],
      doi: '10.1234/nm.2022.045',
      abstractText:
          'We review recent advances in artificial intelligence applications '
          'for clinical decision support, diagnostics, and patient monitoring.',
    ),
    Publication(
      id: 'https://openalex.org/Wmock003',
      title: 'Blockchain Applications in Supply Chain Management',
      publicationYear: 2021,
      publicationDate: '2021-09-20',
      citedByCount: 402,
      journalName: 'IEEE Transactions on Engineering Management',
      authors: [
        Author(id: 'https://openalex.org/Amock006', name: 'Frank Okafor'),
      ],
      doi: '10.1234/ieee.2021.112',
      abstractText:
          'This study evaluates blockchain-based traceability systems and '
          'their impact on transparency and efficiency in global supply chains.',
    ),
    Publication(
      id: 'https://openalex.org/Wmock004',
      title: 'Cybersecurity Challenges in Cloud-Native Systems',
      publicationYear: 2024,
      publicationDate: '2024-02-08',
      citedByCount: 287,
      journalName: 'ACM Computing Surveys',
      authors: [
        Author(id: 'https://openalex.org/Amock007', name: 'Grace Kim'),
        Author(id: 'https://openalex.org/Amock008', name: 'Henry Lopez'),
      ],
      doi: '10.1234/acm.2024.019',
      abstractText:
          'We identify emerging security risks in microservice architectures '
          'and propose mitigation strategies for cloud-native deployments.',
    ),
    Publication(
      id: 'https://openalex.org/Wmock005',
      title: 'Data Science Workflows for Academic Literature Mining',
      publicationYear: 2020,
      publicationDate: '2020-04-12',
      citedByCount: 198,
      journalName: 'Data Mining and Knowledge Discovery',
      authors: [
        Author(id: 'https://openalex.org/Amock009', name: 'Isabella Rossi'),
        Author(id: 'https://openalex.org/Amock010', name: 'James Miller'),
      ],
      doi: '10.1234/dmkd.2020.077',
      abstractText:
          'The authors present reproducible pipelines for extracting trends '
          'from scholarly metadata and visualizing research momentum over time.',
    ),
  ];
}
