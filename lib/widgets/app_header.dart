import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white12,
              child: Icon(Icons.person, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Welcome back',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white54),
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
