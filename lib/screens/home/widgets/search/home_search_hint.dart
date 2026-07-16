import 'package:flutter/material.dart';

class HomeSearchHint extends StatelessWidget {
  final TextEditingController searchController;
  final bool hasSelectedTopics;

  const HomeSearchHint({
    super.key,
    required this.searchController,
    required this.hasSelectedTopics,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
