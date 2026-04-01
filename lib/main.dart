import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BrieflyApp(),
    ),
  );
}

class BrieflyApp extends StatelessWidget {
  const BrieflyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Briefly AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Briefly AI — Theme Ready ✅'),
        ),
      ),
    );
  }
}