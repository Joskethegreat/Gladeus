import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      theme: () {
        final base = ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0B0F),
          colorSchemeSeed: Colors.tealAccent,
          useMaterial3: true,
        );
        // Inter: closest match to Apple's SF system font.
        return base.copyWith(
          textTheme: GoogleFonts.interTextTheme(base.textTheme),
          primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
        );
      }(),
      home: const RootShell(),
    );
  }
}