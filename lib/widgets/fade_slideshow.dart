import 'dart:async';

import 'package:flutter/material.dart';

/// Auto-advancing slideshow that cross-fades between asset images.
/// Stays on the first image when the system asks for reduced motion.
class FadeSlideshow extends StatefulWidget {
  final List<String> assets;
  final Duration interval;
  final Duration fade;
  final Color background;
  final EdgeInsets padding;

  const FadeSlideshow({
    super.key,
    required this.assets,
    this.interval = const Duration(milliseconds: 1000),
    this.fade = const Duration(milliseconds: 400),
    this.background = const Color(0xFFFDFDFB),
    this.padding = const EdgeInsets.all(12),
  });

  @override
  State<FadeSlideshow> createState() => _FadeSlideshowState();
}

class _FadeSlideshowState extends State<FadeSlideshow> {
  Timer? _timer;
  int _index = 0;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final a in widget.assets) {
        precacheImage(ResizeImage(AssetImage(a), width: 1200), context);
      }
    }
    _timer?.cancel();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!reduce && widget.assets.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (mounted) setState(() => _index = (_index + 1) % widget.assets.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: widget.fade,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Padding(
              key: ValueKey(_index),
              padding: widget.padding,
              child: Image.asset(
                widget.assets[_index],
                fit: BoxFit.contain,
                cacheWidth: 1200, // decode smaller than the 2400px source
                gaplessPlayback: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
