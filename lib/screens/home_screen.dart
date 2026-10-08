import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: Text(
            'Home',
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
        ),
      ],
    );
  }
}
