import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width pill button with no fill and a thin light outline.
///
/// With [value] it becomes a settings row: icon + label at the left, the
/// current value and a chevron at the right.
class OutlineLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final VoidCallback? onPressed;

  const OutlineLinkButton({
    super.key,
    required this.label,
    required this.icon,
    this.value,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = OutlinedButton.styleFrom(
      foregroundColor: c.text,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: c.outline),
      minimumSize: const Size.fromHeight(52),
      shape: const StadiumBorder(),
    );

    if (value == null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: style,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style.copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value!, style: TextStyle(color: c.textSecondary)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 22, color: c.textTertiary),
        ],
      ),
    );
  }
}
