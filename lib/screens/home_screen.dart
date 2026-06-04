import 'package:flutter/material.dart';

import '../utils/mock_data.dart';
import 'search_result_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final TextEditingController topicController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Journal Trend Analyzer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: "Research Topic",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchResultScreen(
                      publications: mockPublications,
                    ),
                  ),
                );
              },
              child: const Text("Search"),
            ),
          ],
        ),
      ),
    );
  }
}