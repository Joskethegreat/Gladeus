import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered, frosted alert with a friendly message. Dismiss with the button
/// or by tapping outside it.
Future<void> showFriendlyDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Got it',
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54, // dim to focus on the modal task
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => _FriendlyDialog(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
    ),
    transitionBuilder: (ctx, animation, _, child) {
      // Materialize: scale + fade together, critically damped (no overshoot).
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _FriendlyDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;

  const _FriendlyDialog({
    required this.title,
    required this.message,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = BorderRadius.all(Radius.circular(28));
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: c.glassShadow,
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.compose(
                    outer: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    inner: const ColorFilter.matrix(<double>[
                      // saturate so colours behind glow through the glass
                      1.7, -0.6, -0.1, 0, 0,
                      -0.3, 1.4, -0.1, 0, 0,
                      -0.3, -0.6, 1.9, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.glassTop, c.glassBottom],
                          ),
                          border: Border.all(color: c.glassBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF5A623),
                                foregroundColor: Colors.black87,
                                minimumSize: const Size.fromHeight(48),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(buttonLabel),
                            ),
                          ],
                        ),
                      ),
                      // bright rim along the top edge
                      Positioned(
                        top: 0,
                        left: 24,
                        right: 24,
                        height: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.glassRim.withValues(alpha: 0),
                                c.glassRim,
                                c.glassRim.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
