import '../models/publication_model.dart';
import '../utils/mock_data.dart';

class PublicationController {
  List<Publication> publications = [];

  Future<List<Publication>> search(String topic) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    publications = mockPublications;

    return publications;
  }
}