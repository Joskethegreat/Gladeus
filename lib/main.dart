import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'root_shell.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load(); // so the first frame already uses the saved theme
  runApp(const GladeusApp());
}

ThemeData _buildTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    colorSchemeSeed: Colors.tealAccent,
    useMaterial3: true,
    extensions: [colors],
  );
  // Inter: closest match to Apple's SF system font.
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
  );
}

class GladeusApp extends StatelessWidget {
  const GladeusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Gladeus',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: mode,
        home: const RootShell(),
      ),
    );
  }
}
