import 'package:flutter/material.dart';

import '../controllers/publication_controller.dart';
import 'search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {

  final TextEditingController topicController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }

  Future<void> _search() async {

    if (topicController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a research topic",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final controller =
        PublicationController();

    final publications =
        await controller.search(
      topicController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultScreen(
          publications: publications,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Journal Trend Analyzer",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: topicController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Research Topic",
                hintText:
                    "AI, Blockchain, Data Science...",
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.search),
              ),
              onSubmitted: (_) {
                _search();
              },
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        ElevatedButton.icon(
                      onPressed: _search,
                      icon: const Icon(
                        Icons.search,
                      ),
                      label: const Text(
                        "Search",
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}