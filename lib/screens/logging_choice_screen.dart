import 'package:flutter/material.dart';

import '../models/workout_session.dart';
import '../theme/app_colors.dart';
import '../widgets/fade_slideshow.dart';
import '../widgets/glass_card.dart';
import 'add_session_screen.dart';
import 'camera_log_screen.dart';

class LoggingChoiceScreen extends StatelessWidget {
  const LoggingChoiceScreen({super.key});

  Future<void> _openAndReturn(BuildContext context, Widget screen) async {
    final result = await Navigator.push<WorkoutSession>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    // Only leave this screen once a session was saved. Backing out or
    // cancelling returns here, one level up in the hierarchy.
    if (result != null && context.mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Log Workout')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: _OptionCard(
                  title: 'Camera',
                  description: 'Prop your phone up so your whole body is in view, and we will count your reps for you.',
                  image: const FadeSlideshow(
                    assets: ['assets/images/camera_1.jpg', 'assets/images/camera_2.jpg'],
                  ),
                  onTap: () => _openAndReturn(context, const CameraLogScreen()),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _OptionCard(
                  title: 'Manual',
                  description: 'Already finished? Enter your sets and reps by hand.',
                  image: const ColoredBox(
                    color: Color(0xFFFDFDFB),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(
                        image: ResizeImage(AssetImage('assets/images/log_1.jpg'), width: 1200),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  onTap: () => _openAndReturn(context, const AddSessionScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width glass card: image on top, name and one-line description below.
class _OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget image;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.expand(
      child: GlassCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: image),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: c.textSecondary, fontSize: 15, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
