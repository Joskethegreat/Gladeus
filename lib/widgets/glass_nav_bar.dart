import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/app_colors.dart';

class GlassNavItem {
  final IconData icon;
  final String label;
  const GlassNavItem(this.icon, this.label);
}

/// Floating, translucent "liquid glass" bottom bar. Four tabs split around a
/// centre action button; a glass lens slides between tabs on a spring that
/// is interruptible and stretches with velocity.
class GlassNavBar extends StatefulWidget {
  final List<GlassNavItem> items; // exactly 4
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterTap,
  }) : assert(items.length == 4);

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  static const double _barHeight = 68;
  static const double _centerSize = 68;
  static const _accent = Color(0xFFF5A623);

  // Spring: critically-ish damped with a touch of bounce for a liquid feel.
  static const _spring = SpringDescription(mass: 1, stiffness: 320, damping: 24);

  late final AnimationController _ctrl;
  bool _centerPressed = false;

  // Tabs live in slots 0,1,(centre = 2),3,4.
  static int _slotFor(int tab) => tab < 2 ? tab : tab + 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this, value: _slotFor(widget.currentIndex).toDouble());
  }

  @override
  void didUpdateWidget(GlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      // Start from the live value and velocity so interruptions stay continuous.
      _ctrl.animateWith(SpringSimulation(
        _spring,
        _ctrl.value,
        _slotFor(widget.currentIndex).toDouble(),
        _ctrl.velocity,
      ));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
      child: SizedBox(
        height: _barHeight + 20,
        child: LayoutBuilder(builder: (context, c) {
          final slotW = c.maxWidth / 5;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Glass pill
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: _glassPill(slotW, reduceMotion),
              ),
              // Centre action button
              Positioned(
                bottom: 20,
                child: _centerButton(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _glassPill(double slotW, bool reduceMotion) {
    const radius = BorderRadius.all(Radius.circular(36));
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: c.glassShadow, blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            inner: const ColorFilter.matrix(<double>[
              // saturate ~1.6 so what's behind glows through the glass
              1.7, -0.6, -0.1, 0, 0,
              -0.3, 1.4, -0.1, 0, 0,
              -0.3, -0.6, 1.9, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              // Light catching the surface: brighter top-left, dim bottom-right.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.glassTop, c.glassBottom],
              ),
              border: Border.all(color: c.glassBorder, width: 1),
            ),
            child: Stack(
              children: [
                // Refractive rim: bright top edge highlight.
                Positioned(
                  left: 24,
                  right: 24,
                  top: 0,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        c.glassRim.withValues(alpha: 0),
                        c.glassRim,
                        c.glassRim.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
                // Sliding liquid lens
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final v = reduceMotion ? 0.0 : _ctrl.velocity;
                    final stretch = 1 + (v.abs() / 14).clamp(0.0, 0.35); // squash & stretch
                    final squash = 1 - (stretch - 1) * 0.5;
                    const lensW = 64.0;
                    const lensH = 52.0;
                    final cx = (_ctrl.value + 0.5) * slotW;
                    return Positioned(
                      left: cx - lensW / 2,
                      top: (_barHeight - lensH) / 2,
                      width: lensW,
                      height: lensH,
                      child: Transform.scale(
                        scaleX: stretch,
                        scaleY: squash,
                        child: _lens(),
                      ),
                    );
                  },
                ),
                // Tabs
                Row(
                  children: [
                    for (var slot = 0; slot < 5; slot++)
                      Expanded(
                        child: slot == 2 ? const SizedBox() : _tab(slot < 2 ? slot : slot - 1),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lens() {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.lensTop, c.lensBottom],
        ),
        border: Border.all(color: c.lensBorder, width: 1),
        boxShadow: [
          BoxShadow(color: c.lensGlow, blurRadius: 12, spreadRadius: -2),
        ],
      ),
    );
  }

  Widget _tab(int index) {
    final item = widget.items[index];
    final selected = index == widget.currentIndex;
    final c = context.colors;
    return Listener(
      // Respond on pointer-down, not release.
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (!selected) widget.onTap(index);
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(item.icon, size: 24, color: selected ? c.text : c.textTertiary),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.text : c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerButton() {
    return Listener(
      onPointerDown: (_) => setState(() => _centerPressed = true),
      onPointerUp: (_) => setState(() => _centerPressed = false),
      onPointerCancel: (_) => setState(() => _centerPressed = false),
      child: GestureDetector(
        onTap: widget.onCenterTap,
        child: AnimatedScale(
          scale: _centerPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: _centerSize,
            height: _centerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFC857), _accent],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.photo_camera_rounded, size: 30, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
