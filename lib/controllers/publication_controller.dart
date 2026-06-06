import '../models/publication_model.dart';
import '../utils/mock_data.dart';

class PublicationController {
  List<Publication> publications = [];

  Future<List<Publication>> search(String topic) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    final keyword = topic.toLowerCase();

    publications = mockPublications.where((publication) {
      return publication.title
              .toLowerCase()
              .contains(keyword) ||

          publication.journal
              .toLowerCase()
              .contains(keyword) ||

          publication.authors
              .join(' ')
              .toLowerCase()
              .contains(keyword);
    }).toList();

    return publications;
  }
}