import 'package:flutter/material.dart';

import '../models/publication_model.dart';
import 'publication_detail_screen.dart';

class SearchResultScreen extends StatelessWidget {
  final List<Publication> publications;

  const SearchResultScreen({
    super.key,
    required this.publications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Results"),
      ),
      body: ListView.builder(
        itemCount: publications.length,
        itemBuilder: (context, index) {
          final publication = publications[index];

          return Card(
            child: ListTile(
              title: Text(publication.title),
              subtitle: Text(
                "${publication.year} • ${publication.citations} citations",
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(
                      publication: publication,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}