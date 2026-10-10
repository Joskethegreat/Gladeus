import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/option_sheet.dart';
import '../widgets/outline_link_button.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

class _Setting {
  final String key;
  final String label;
  final IconData icon;
  final List<String> options;

  const _Setting(this.key, this.label, this.icon, this.options);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _settings = [
    _Setting('theme', 'Theme', Icons.palette_outlined, ['Light', 'Dark']),
    _Setting('language', 'Language', Icons.language_rounded, ['English', 'Malay']),
    _Setting('notification', 'Notification', Icons.notifications_none_rounded, ['On', 'Off']),
  ];

  // Defaults: first option of each, except theme (the app is dark) and notifications on.
  final Map<String, String> _values = {
    'theme': 'Dark',
    'language': 'English',
    'notification': 'On',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final s in _settings) {
        final saved = prefs.getString('setting_${s.key}');
        if (saved != null && s.options.contains(saved)) _values[s.key] = saved;
      }
    });
  }

  Future<void> _pick(_Setting s) async {
    final choice = await showOptionSheet(
      context,
      title: s.label,
      options: s.options,
      selected: _values[s.key]!,
    );
    if (choice == null) return;
    setState(() => _values[s.key] = choice);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('setting_${s.key}', choice);
    if (s.key == 'theme') ThemeController.apply(choice);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      // Back button at top left (default leading), transparent so the title leads.
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 20),
            child: Text(
              'Settings',
              style: TextStyle(
                color: c.text,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
          for (final s in _settings) ...[
            OutlineLinkButton(
              label: s.label,
              icon: s.icon,
              value: _values[s.key],
              onPressed: () => _pick(s),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
