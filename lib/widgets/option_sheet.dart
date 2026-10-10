import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom sheet with radio options. Returns the chosen option, or null if
/// dismissed. Selecting an option confirms it and closes the sheet.
Future<String?> showOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black54, // dim to focus on the modal task
    builder: (_) => _OptionSheet(title: title, options: options, selected: selected),
  );
}

class _OptionSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selected;

  const _OptionSheet({required this.title, required this.options, required this.selected});

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  static const _accent = Color(0xFFF5A623);
  late String _value = widget.selected;

  Future<void> _choose(String? v) async {
    if (v == null) return;
    setState(() => _value = v); // instant feedback on press
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(28));
    final c = context.colors;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: c.sheetBackground,
            borderRadius: radius,
            border: Border(top: BorderSide(color: c.sheetBorder)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.sheetHandle,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: _value,
                    onChanged: _choose,
                    child: Column(
                      children: [
                        for (final o in widget.options)
                          RadioListTile<String>(
                            value: o,
                            activeColor: _accent,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              o,
                              style: TextStyle(color: c.text, fontSize: 17),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
