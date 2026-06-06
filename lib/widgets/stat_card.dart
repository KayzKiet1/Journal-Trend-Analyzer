// TODO: Implement StatCard - Assigned to Person 1 + Person 4
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [Text(title), Text(value)],
      ),
    );
  }
}
