import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const JournalTrendAnalyzerApp());
}

class JournalTrendAnalyzerApp extends StatelessWidget {
  const JournalTrendAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal Trend Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const HomeScreen(),
    );
  }
}