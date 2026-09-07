import 'package:flutter/material.dart';
import 'root_shell.dart';

void main() {
  runApp(const GladeusApp());
}

class GladeusApp extends StatelessWidget {
  const GladeusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gladeus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        colorSchemeSeed: Colors.tealAccent,
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}