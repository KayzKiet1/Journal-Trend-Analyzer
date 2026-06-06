import 'package:flutter/material.dart';

import '../models/publication_model.dart';

class PublicationDetailScreen
    extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
  });

  Widget buildInfoTile(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Publication Detail"),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  publication.title,
                  style:
                      const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                buildInfoTile(
                  "Year",
                  publication.year
                      .toString(),
                ),

                buildInfoTile(
                  "Journal",
                  publication.journal,
                ),

                buildInfoTile(
                  "Citations",
                  publication.citations
                      .toString(),
                ),

                buildInfoTile(
                  "Authors",
                  publication.authors
                      .join(', '),
                ),

                buildInfoTile(
                  "DOI",
                  publication.doi,
                ),

                const Divider(
                  height: 30,
                ),

                const Text(
                  "Abstract",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  publication.abstractText,
                  style:
                      const TextStyle(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}