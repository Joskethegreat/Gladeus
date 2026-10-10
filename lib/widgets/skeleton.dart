import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Generic loading skeleton: a heading bar plus a few card placeholders,
/// all sharing one looping shimmer.
class SkeletonScreen extends StatefulWidget {
  const SkeletonScreen({super.key});

  @override
  State<SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends State<SkeletonScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show a static skeleton instead of the sweep.
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.divider; // resting colour
    final highlight = c.glassTop.withValues(alpha: 0.5); // sweeping highlight

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Slides the highlight band from off-left to off-right.
        final t = _ctrl.value * 3 - 1;
        final shader = LinearGradient(
          begin: Alignment(-1 + t, -0.3),
          end: Alignment(1 + t, 0.3),
          colors: [base, highlight, base],
          stops: const [0.35, 0.5, 0.65],
        );

        Widget bar(double width, double height, {double radius = 8}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: shader,
          ),
        );

        Widget card() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.glassBorder),
            color: c.glassBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(140, 20),
              const SizedBox(height: 16),
              bar(double.infinity, 14),
              const SizedBox(height: 10),
              bar(double.infinity, 14),
              const SizedBox(height: 10),
              bar(180, 14),
            ],
          ),
        );

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: bar(180, 34, radius: 10), // large heading placeholder
              ),
            ),
            card(),
            const SizedBox(height: 16),
            card(),
            const SizedBox(height: 16),
            card(),
          ],
        );
      },
    );
  }
}
