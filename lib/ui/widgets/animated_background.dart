// lib/ui/widgets/animated_background.dart
// =============================================================================
// ANIMATED BACKGROUND — Full-screen particle engine using CustomPainter.
//
// Architecture:
//   • AnimatedBackground (StatefulWidget) owns the AnimationController.
//     It listens to BOTH its own ticker and the parent's ScrollController
//     via Listenable.merge([]) so the Canvas repaints on either change.
//   • A factory function (_selectPainter) picks the right CustomPainter
//     subclass based on the current WeatherState.
//   • Each painter receives animValue (0.0–1.0 looping) + scrollOffset.
//
// Parallax implementation:
//   Every particle's y-position includes  scrollOffset * 0.3  as an offset.
//   When the user scrolls the foreground down by 100px, particles shift down
//   only 30px — making them appear further away than the foreground cards.
//
// Painter overview:
//   _RainPainter   → short diagonal vector lines, varying speed/length/alpha
//   _SnowPainter   → circles with sine-wave horizontal drift
//   _SunnyPainter  → rotating radiant rays from a pulsing sun disc
//   _CloudyPainter → slowly drifting blurred oval cloud shapes
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/weather_model.dart';
import '../../utils/weather_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBackground widget
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedBackground extends StatefulWidget {
  final WeatherState       weatherState;
  final WeatherColorTheme  theme;
  final ScrollController   scrollController;

  const AnimatedBackground({
    super.key,
    required this.weatherState,
    required this.theme,
    required this.scrollController,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A long duration (10 s) makes animValue advance slowly and smoothly.
    // The painters use it as a normalised time parameter for all motion.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder with a merged Listenable means this subtree repaints
    // whenever EITHER the animation ticks OR the scroll position changes.
    // No setState() calls are needed — it's entirely reactive.
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, widget.scrollController]),
      builder: (context, _) {
        final scrollOffset = widget.scrollController.hasClients
            ? widget.scrollController.offset.clamp(0.0, double.infinity)
            : 0.0;

        return SizedBox.expand(
          child: CustomPaint(
            painter: _selectPainter(
              animValue:    _controller.value,
              scrollOffset: scrollOffset,
            ),
          ),
        );
      },
    );
  }

  CustomPainter _selectPainter({
    required double animValue,
    required double scrollOffset,
  }) {
    switch (widget.weatherState) {
      case WeatherState.rainy:
      case WeatherState.stormy:
        return _RainPainter(
          animValue:    animValue,
          scrollOffset: scrollOffset,
          theme:        widget.theme,
          isStormy:     widget.weatherState == WeatherState.stormy,
        );
      case WeatherState.snowy:
        return _SnowPainter(
          animValue:    animValue,
          scrollOffset: scrollOffset,
          theme:        widget.theme,
        );
      case WeatherState.sunny:
      case WeatherState.partlyCloudy:
        return _SunnyPainter(
          animValue:    animValue,
          scrollOffset: scrollOffset,
          theme:        widget.theme,
        );
      case WeatherState.cloudy:
      case WeatherState.foggy:
        return _CloudyPainter(
          animValue:    animValue,
          scrollOffset: scrollOffset,
          theme:        widget.theme,
        );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RAIN PAINTER
//
// Draws [_dropCount] short diagonal line-streaks that fall continuously.
// Each drop has a random: x-position, speed multiplier, length, and opacity.
// The y-position is computed as:
//   rawY = (phase + animValue * speed) % 1.0
// which gives a value in [0, 1] that we multiply by the canvas height.
// Adding scrollOffset * 0.3 creates the parallax shift.
// ═════════════════════════════════════════════════════════════════════════════
class _RainPainter extends CustomPainter {
  final double            animValue;
  final double            scrollOffset;
  final WeatherColorTheme theme;
  final bool              isStormy;

  // Particle count — higher = heavier rain
  static const int _dropCount = 80;

  // Fixed-seed RNG so particle layout is deterministic across rebuilds.
  static final _rng = Random(42);

  // Static particle properties (computed once, reused every frame)
  static final _dropX       = List.generate(_dropCount, (_) => _rng.nextDouble());
  static final _dropPhase   = List.generate(_dropCount, (_) => _rng.nextDouble());
  static final _dropSpeed   = List.generate(_dropCount, (_) => 0.6 + _rng.nextDouble() * 0.8);
  static final _dropLength  = List.generate(_dropCount, (_) => 0.025 + _rng.nextDouble() * 0.04);
  static final _dropOpacity = List.generate(_dropCount, (_) => 0.30 + _rng.nextDouble() * 0.50);

  const _RainPainter({
    required this.animValue,
    required this.scrollOffset,
    required this.theme,
    required this.isStormy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background gradient ──────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = theme.backgroundGradient
            .createShader(Offset.zero & size),
    );

    // ── Rain streaks ─────────────────────────────────────────────────────
    final dropPaint = Paint()
      ..strokeWidth = isStormy ? 1.8 : 1.1
      ..strokeCap   = StrokeCap.round;

    // Slight tilt (like wind-blown rain)
    const tiltRad = -0.12; // radians; negative = lean slightly right

    for (int i = 0; i < _dropCount; i++) {
      // Normalised y in [0, 1], wrapping continuously using modulo.
      // The scrollOffset term is the parallax: background moves 30% of scroll.
      final rawY = (_dropPhase[i]
              + animValue * _dropSpeed[i]
              + scrollOffset * 0.3 / size.height)
          .remainder(1.0)
          .abs();

      final x      = _dropX[i] * size.width;
      final yStart = rawY * size.height;
      final yEnd   = yStart + _dropLength[i] * size.height;
      final xTilt  = sin(tiltRad) * (yEnd - yStart);

      dropPaint.color = theme.particleColor.withOpacity(_dropOpacity[i]);
      canvas.drawLine(
        Offset(x, yStart),
        Offset(x + xTilt, yEnd),
        dropPaint,
      );
    }

    // ── Lightning flash for stormy conditions ─────────────────────────
    // The flash fires briefly once every ~7 animation loops.
    if (isStormy && (animValue * 10).floor() % 7 == 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.animValue != animValue || old.scrollOffset != scrollOffset;
}

// ═════════════════════════════════════════════════════════════════════════════
// SNOW PAINTER
//
// Draws [_flakeCount] circular snowflakes drifting slowly downward with a
// sine-wave horizontal oscillation.  Larger flakes fall faster to simulate
// realistic depth (atmosphere perspective).
// ═════════════════════════════════════════════════════════════════════════════
class _SnowPainter extends CustomPainter {
  final double            animValue;
  final double            scrollOffset;
  final WeatherColorTheme theme;

  static const int _flakeCount = 60;
  static final _rng = Random(7);

  // Static particle properties
  static final _flakeX         = List.generate(_flakeCount, (_) => _rng.nextDouble());
  static final _flakePhase     = List.generate(_flakeCount, (_) => _rng.nextDouble());
  static final _flakeSpeed     = List.generate(_flakeCount, (_) => 0.08 + _rng.nextDouble() * 0.18);
  static final _flakeRadius    = List.generate(_flakeCount, (_) => 2.0 + _rng.nextDouble() * 4.0);
  static final _driftFreq      = List.generate(_flakeCount, (_) => 0.5 + _rng.nextDouble() * 1.5);
  static final _driftAmp       = List.generate(_flakeCount, (_) => 0.012 + _rng.nextDouble() * 0.025);
  static final _flakeOpacity   = List.generate(_flakeCount, (_) => 0.40 + _rng.nextDouble() * 0.55);

  const _SnowPainter({
    required this.animValue,
    required this.scrollOffset,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ───────────────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = theme.backgroundGradient
            .createShader(Offset.zero & size),
    );

    // ── Snowflakes ───────────────────────────────────────────────────────
    final flakePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _flakeCount; i++) {
      // Vertical fall with parallax offset
      final rawY = (_flakePhase[i]
              + animValue * _flakeSpeed[i]
              + scrollOffset * 0.3 / size.height)
          .remainder(1.0)
          .abs();

      // Horizontal sine-wave drift — the  2π * driftFreq  factor controls
      // how many oscillation cycles occur per 10-second animation loop.
      final xDrift = sin(animValue * 2 * pi * _driftFreq[i]) *
          _driftAmp[i] * size.width;
      final x = (_flakeX[i] * size.width + xDrift).clamp(0.0, size.width);
      final y = rawY * size.height;

      flakePaint.color = theme.particleColor.withOpacity(_flakeOpacity[i]);
      canvas.drawCircle(Offset(x, y), _flakeRadius[i], flakePaint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) =>
      old.animValue != animValue || old.scrollOffset != scrollOffset;
}

// ═════════════════════════════════════════════════════════════════════════════
// SUNNY PAINTER
//
// Draws a pulsing sun disc in the upper-right corner with 8 rotating radiant
// rays.  Each ray fades from opaque (near the sun) to transparent (at its tip)
// using a LinearGradient shader on the stroke paint.
//
// The sun y-position shifts with scrollOffset * 0.3 (parallax).
// ═════════════════════════════════════════════════════════════════════════════
class _SunnyPainter extends CustomPainter {
  final double            animValue;
  final double            scrollOffset;
  final WeatherColorTheme theme;

  const _SunnyPainter({
    required this.animValue,
    required this.scrollOffset,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background gradient ──────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = theme.backgroundGradient
            .createShader(Offset.zero & size),
    );

    // Sun position: upper-right quadrant; shifts up as user scrolls down.
    final sunX = size.width  * 0.72;
    final sunY = size.height * 0.16 - scrollOffset * 0.3;

    // Pulse radius: ±8px oscillation per loop
    final glowR = 48.0 + sin(animValue * 2 * pi) * 8.0;

    // ── Outer atmospheric glow ──────────────────────────────────────────
    canvas.drawCircle(
      Offset(sunX, sunY),
      glowR * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.accent.withOpacity(0.28),
            theme.accent.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(sunX, sunY), radius: glowR * 3.2),
        ),
    );

    // ── Sun disc ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(sunX, sunY),
      glowR * 0.45,
      Paint()..color = theme.accent.withOpacity(0.88),
    );

    // ── Radiant rays ─────────────────────────────────────────────────────
    const rayCount = 8;
    // Slow rotation: full 360° every 10 × 10 = 100 seconds
    final rotation = animValue * 2 * pi * 0.1;
    final innerR   = glowR * 0.55; // Ray starts just outside the disc

    final rayPaint = Paint()
      ..strokeWidth = 2.2
      ..strokeCap   = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final angle  = (i / rayCount) * 2 * pi + rotation;
      // Ray length pulses independently per ray for a lively feel
      final rayLen = 75.0 + sin(animValue * 2 * pi + i * 1.2) * 18.0;

      final startX = sunX + cos(angle) * innerR;
      final startY = sunY + sin(angle) * innerR;
      final endX   = sunX + cos(angle) * (innerR + rayLen);
      final endY   = sunY + sin(angle) * (innerR + rayLen);

      // Gradient: opaque at base, transparent at tip
      rayPaint.shader = LinearGradient(
        colors: [
          theme.accent.withOpacity(0.75),
          theme.accent.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
      );

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(_SunnyPainter old) =>
      old.animValue != animValue || old.scrollOffset != scrollOffset;
}

// ═════════════════════════════════════════════════════════════════════════════
// CLOUDY PAINTER
//
// Draws soft, blurred oval "cloud" shapes that drift very slowly to the right.
// The blur mask filter gives them a diffuse, atmospheric quality.
// Used for both cloudy and foggy states.
// ═════════════════════════════════════════════════════════════════════════════
class _CloudyPainter extends CustomPainter {
  final double            animValue;
  final double            scrollOffset;
  final WeatherColorTheme theme;

  static const int _cloudCount = 5;
  static final _rng = Random(99);

  // Fixed cloud vertical positions spread across the top ~70% of the screen
  static final _cloudY     = List.generate(_cloudCount,
      (i) => 0.04 + i * 0.15 + _rng.nextDouble() * 0.06);
  static final _cloudWidth  = List.generate(_cloudCount,
      (_) => 0.45 + _rng.nextDouble() * 0.35);
  static final _cloudSpeed  = List.generate(_cloudCount,
      (_) => 0.015 + _rng.nextDouble() * 0.03);
  static final _cloudPhase  = List.generate(_cloudCount,
      (_) => _rng.nextDouble());

  const _CloudyPainter({
    required this.animValue,
    required this.scrollOffset,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ───────────────────────────────────────────────────────
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = theme.backgroundGradient
            .createShader(Offset.zero & size),
    );

    // ── Drifting clouds ──────────────────────────────────────────────────
    final cloudPaint = Paint()
      ..style      = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28.0);

    for (int i = 0; i < _cloudCount; i++) {
      // Clouds drift rightward and wrap around
      final rawX = (_cloudPhase[i] + animValue * _cloudSpeed[i])
          .remainder(1.4) - 0.2; // Allow off-screen on both sides
      final x = rawX * size.width;
      final y = _cloudY[i] * size.height - scrollOffset * 0.2;
      final w = _cloudWidth[i] * size.width;
      final h = w * 0.38;

      cloudPaint.color = theme.particleColor.withOpacity(0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          cloudPaint);
    }
  }

  @override
  bool shouldRepaint(_CloudyPainter old) =>
      old.animValue != animValue || old.scrollOffset != scrollOffset;
}
