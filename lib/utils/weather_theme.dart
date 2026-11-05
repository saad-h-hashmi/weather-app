// lib/utils/weather_theme.dart
// =============================================================================
// WEATHER THEME — Dynamic colour-harmonisation system.
//
// Architecture decision:  Instead of hard-coding colours throughout the UI,
// every widget receives a [WeatherColorTheme] object derived from the current
// [WeatherState].  This makes it trivial to change a whole weather state's
// palette in one place, and it satisfies the "dynamic colour harmonisation"
// requirement without scattering magic-colour literals across files.
//
// How it works:
//   1. The provider exposes WeatherData which has a `condition.state` getter.
//   2. HomeScreen calls WeatherColorTheme.fromState(state) once per rebuild.
//   3. Every child widget receives the theme object as a constructor argument.
//   4. No widget imports this file except through the object it was given.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/weather_model.dart';

/// An immutable colour palette tied to a single weather condition.
class WeatherColorTheme {
  // Three-stop background gradient (top → mid → bottom)
  final Color gradientTop;
  final Color gradientMid;
  final Color gradientBottom;

  /// Accent colour used for chart lines, icon tints, active badges, etc.
  final Color accent;

  /// Primary text — white on most dark backgrounds.
  final Color textPrimary;

  /// Secondary text — slightly muted, used for labels and sub-values.
  final Color textSecondary;

  /// Semi-transparent fill for glass cards.
  /// Must be low-alpha white so the blurred backdrop shows through.
  final Color cardFill;

  /// Colour of the animated background particles (rain drops, snowflakes…).
  final Color particleColor;

  const WeatherColorTheme({
    required this.gradientTop,
    required this.gradientMid,
    required this.gradientBottom,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardFill,
    required this.particleColor,
  });

  // ── COMPUTED PROPERTIES ────────────────────────────────────────────────────

  /// Ready-to-use [LinearGradient] for the fullscreen background container.
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientTop, gradientMid, gradientBottom],
        stops: const [0.0, 0.5, 1.0],
      );

  // ── FACTORY ───────────────────────────────────────────────────────────────
  /// Returns the correct palette for a given [WeatherState].
  /// Each palette was designed to feel emotionally appropriate:
  ///   • Sunny  → warm amber-oranges, evokes heat and brightness
  ///   • Rainy  → deep navy-blues, feels cool and overcast
  ///   • Stormy → dark purples with electric accents, ominous and dramatic
  ///   • Snowy  → pale ice-blues fading to white, cold and clean
  ///   • Foggy  → muted blue-greys, low contrast, indistinct
  static WeatherColorTheme fromState(WeatherState state) {
    switch (state) {
      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.sunny:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFFFF6B35), // Vivid orange
          gradientMid:    Color(0xFFFFAB00), // Deep amber
          gradientBottom: Color(0xFF1976D2), // Sky blue horizon
          accent:         Color(0xFFFFD740), // Golden yellow
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFFFF3E0), // Cream
          cardFill:       Color(0x25FFFFFF),
          particleColor:  Color(0x88FFE082), // Golden particles
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.partlyCloudy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF1565C0), // Mid blue
          gradientMid:    Color(0xFF42A5F5), // Light blue
          gradientBottom: Color(0xFF87CEEB), // Sky
          accent:         Color(0xFFFFD740), // Sun peeking through
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFBBDEFB), // Pale blue
          cardFill:       Color(0x28FFFFFF),
          particleColor:  Color(0x88FFFFFF),
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.cloudy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF455A64), // Blue-grey dark
          gradientMid:    Color(0xFF546E7A), // Blue-grey mid
          gradientBottom: Color(0xFF78909C), // Blue-grey light
          accent:         Color(0xFF80CBC4), // Teal pop
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFCFD8DC), // Light grey
          cardFill:       Color(0x28FFFFFF),
          particleColor:  Color(0x55ECEFF1),
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.rainy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF1A237E), // Deep indigo
          gradientMid:    Color(0xFF1565C0), // Royal blue
          gradientBottom: Color(0xFF1E88E5), // Bright blue
          accent:         Color(0xFF64B5F6), // Soft blue highlight
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFBBDEFB), // Ice blue
          cardFill:       Color(0x22FFFFFF),
          particleColor:  Color(0x99BBDEFB), // Rain drop blue
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.stormy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF1A1A2E), // Near black
          gradientMid:    Color(0xFF16213E), // Very dark navy
          gradientBottom: Color(0xFF4A148C), // Deep purple
          accent:         Color(0xFFCE93D8), // Electric purple
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFE1BEE7), // Lavender
          cardFill:       Color(0x20FFFFFF),
          particleColor:  Color(0x88CE93D8), // Purple rain
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.snowy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF1565C0), // Cold blue
          gradientMid:    Color(0xFF42A5F5), // Icy blue
          gradientBottom: Color(0xFFE3F2FD), // Near white
          accent:         Color(0xFFA5D6A7), // Mint (warmth contrast)
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFE3F2FD), // Very pale blue
          cardFill:       Color(0x30FFFFFF),
          particleColor:  Color(0xCCFFFFFF), // White snowflakes
        );

      // ──────────────────────────────────────────────────────────────────────
      case WeatherState.foggy:
        return const WeatherColorTheme(
          gradientTop:    Color(0xFF37474F), // Dark slate
          gradientMid:    Color(0xFF607D8B), // Blue-grey
          gradientBottom: Color(0xFFB0BEC5), // Light grey
          accent:         Color(0xFF80DEEA), // Aqua tint
          textPrimary:    Colors.white,
          textSecondary:  Color(0xFFCFD8DC),
          cardFill:       Color(0x30FFFFFF),
          particleColor:  Color(0x55ECEFF1), // Misty white
        );
    }
  }
}
