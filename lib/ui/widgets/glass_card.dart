// lib/ui/widgets/glass_card.dart
// =============================================================================
// GLASS CARD — Reusable frosted-glass container.
//
// How glassmorphism works in Flutter:
//   1. BackdropFilter intercepts everything drawn BEHIND this widget.
//   2. ImageFilter.blur applies a Gaussian blur to that captured layer.
//   3. The blurred image is then painted as the "background" of this widget.
//   4. A semi-transparent white fill (cardFill, ~15% opacity) sits on top,
//      tinting the blur slightly so text remains readable.
//   5. A thin bright border simulates light catching the edge of glass.
//
// Performance note:
//   BackdropFilter is an expensive compositing operation.  On desktop Chrome
//   it runs at 60 fps comfortably because the GPU handles blending.  On weak
//   mobile GPUs it can cause jank — the cardBlurSigma constant can be reduced
//   in AppConstants to trade quality for performance.
//
// Usage:
//   GlassCard(
//     theme: theme,
//     child: Text('Hello'),
//   )
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../utils/app_constants.dart';
import '../../utils/weather_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget               child;
  final EdgeInsetsGeometry   padding;
  final double               borderRadius;
  final WeatherColorTheme?   theme;
  final double?              width;
  final double?              height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding      = const EdgeInsets.all(20),
    this.borderRadius = AppConstants.cardBorderRadius,
    this.theme,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // ClipRRect is essential: without it the blur effect extends beyond the
    // rounded corners and bleeds into surrounding widgets.
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.cardBlurSigma,
          sigmaY: AppConstants.cardBlurSigma,
        ),
        child: Container(
          width:   width,
          height:  height,
          padding: padding,
          decoration: BoxDecoration(
            // The low-alpha fill is what makes the glass "tinted" rather
            // than a pure mirror.  The exact value is tuned per theme.
            color:        theme?.cardFill ?? const Color(0x25FFFFFF),
            borderRadius: BorderRadius.circular(borderRadius),
            border:       Border.all(
              // A bright top edge simulates a specular highlight on glass.
              color: Colors.white.withOpacity(0.22),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
