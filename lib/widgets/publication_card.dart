import 'package:flutter/material.dart';
import '../models/publication_model.dart';

class PublicationCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const PublicationCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          publication.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Text(
              "📅 ${publication.year}",
            ),

            Text(
              "📚 ${publication.journal}",
            ),

            Text(
              "⭐ ${publication.citations} citations",
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
        onTap: onTap,
      ),
    );
  }
}