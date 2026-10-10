import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;

  const AppHeader({super.key, this.name = ''});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.divider,
              child: Icon(Icons.person, color: c.textTertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name.isEmpty ? 'Welcome back' : 'Welcome back, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textSecondary, fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(Icons.notifications_none, color: c.textTertiary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
