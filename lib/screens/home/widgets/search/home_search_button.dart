import 'package:flutter/material.dart';

import '../../../../widgets/app_button.dart';

class HomeSearchButton extends StatelessWidget {
  final TextEditingController searchController;
  final int selectedTopicCount;
  final bool isLoadingDashboard;
  final VoidCallback onSearch;

  const HomeSearchButton({
    super.key,
    required this.searchController,
    required this.selectedTopicCount,
    required this.isLoadingDashboard,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim();
    final canSearch = query.length >= 2;
    final filterLabel = selectedTopicCount == 0
        ? ''
        : ' + $selectedTopicCount topic filters';
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AppButton(
        key: const Key('home_search_button'),
        text: isLoadingDashboard
            ? 'Loading Research Overview...'
            : 'Search Journal Works$filterLabel',
        onPressed: isLoadingDashboard || !canSearch ? null : onSearch,
      ),
    );
  }
}
