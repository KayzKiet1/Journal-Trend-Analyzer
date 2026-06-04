import 'package:flutter/material.dart';

import '../models/publication_model.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publication Detail"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              publication.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text("Year: ${publication.year}"),
            Text("Journal: ${publication.journal}"),
            Text("Citations: ${publication.citations}"),

            const SizedBox(height: 10),

            Text(
              "Authors: ${publication.authors.join(', ')}",
            ),

            const SizedBox(height: 10),

            Text("DOI: ${publication.doi}"),

            const SizedBox(height: 20),

            const Text(
              "Abstract",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(publication.abstractText),
          ],
        ),
      ),
    );
  }
}