import 'package:flutter/material.dart';

void main() {
  runApp(const DtsDriverApp());
}

class DtsDriverApp extends StatelessWidget {
  const DtsDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTS Conductor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('DTS Conductor — iniciar con /fase-4'),
        ),
      ),
    );
  }
}
