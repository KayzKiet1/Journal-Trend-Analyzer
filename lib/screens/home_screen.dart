import 'package:flutter/material.dart';

import '../controllers/publication_controller.dart';
import 'search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController topicController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    topicController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final topic = topicController.text.trim();

    if (topic.isEmpty) {
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

    try {
      final controller = PublicationController();

      final publications = await controller.search(topic);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (publications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No publications found",
            ),
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultScreen(
            publications: publications,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Journal Trend Analyzer",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            Icon(
              Icons.auto_graph,
              size: 90,
              color: Colors.indigo.shade700,
            ),

            const SizedBox(height: 20),

            const Text(
              "Journal Trend Analyzer",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Search research publications and explore academic trends.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: "Research Topic",
                hintText: "AI, Blockchain, Data Science...",
                prefixIcon: const Icon(
                  Icons.search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),

            const SizedBox(height: 25),

            isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        "Searching publications...",
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _search,
                      icon: const Icon(
                        Icons.search,
                      ),
                      label: const Text(
                        "Search",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 40),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    const Text(
                      "Features",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _featureItem(
                      Icons.article,
                      "Search Publications",
                    ),

                    _featureItem(
                      Icons.menu_book,
                      "View Publication Details",
                    ),

                    _featureItem(
                      Icons.trending_up,
                      "Analyze Research Trends",
                    ),

                    _featureItem(
                      Icons.bar_chart,
                      "Dashboard Statistics",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(
    IconData icon,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }
}