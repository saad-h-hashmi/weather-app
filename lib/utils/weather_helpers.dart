// lib/utils/weather_helpers.dart
// =============================================================================
// WEATHER HELPERS — Pure, stateless utility functions.
//
// Design principle:  These are all static methods with no side-effects.
// They can be called from any layer of the app without creating an instance,
// and they are trivially unit-testable because they have no dependencies.
// =============================================================================

import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherHelpers {
  WeatherHelpers._(); // Prevents instantiation

  // ── WIND DIRECTION ──────────────────────────────────────────────────────────
  /// Converts a meteorological wind-direction angle (0–360°) to a compass
  /// abbreviation such as "NNE" or "SW".
  static String windDirection(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    // Divide the circle into 8 equal sectors of 45° each.
    // Adding 22.5° before dividing centres each sector on its label.
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  // ── DATE / TIME FORMATTING ──────────────────────────────────────────────────
  /// Returns a human-friendly day name.
  /// Returns 'Today' or 'Tomorrow' instead of the weekday name when appropriate.
  static String formatDay(DateTime dt) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (_isToday(dt))    return 'Today';
    if (_isTomorrow(dt)) return 'Tomorrow';
    return days[dt.weekday % 7];
  }

  /// Returns a short hour string such as "3 PM" or "12 AM".
  static String formatHour(DateTime dt) {
    final h = dt.hour;
    if (h == 0)  return '12 AM';
    if (h == 12) return '12 PM';
    return h < 12 ? '$h AM' : '${h - 12} PM';
  }

  /// Returns how long ago [dt] was in human-readable form.
  /// Used to show "Updated 5m ago" in the header.
  static String formatLastUpdated(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Returns a formatted clock time string like "6:30 AM".
  static String formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    if (h == 0)  return '12:$m AM';
    if (h == 12) return '12:$m PM';
    return h < 12 ? '$h:$m AM' : '${h - 12}:$m PM';
  }

  static bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static bool _isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }

  // ── SMART WEATHER INSIGHTS ──────────────────────────────────────────────────
  /// The centrepiece analytical function.
  ///
  /// Analyses multiple metrics from [data] and assembles a natural-language
  /// summary appropriate for the current conditions.
  ///
  /// Each "insight bullet" is separated by "  •  " for readability.
  /// The function covers: UV, temperature feel, humidity, wind, special
  /// condition warnings, and an evening study session hint.
  static String generateInsight(WeatherData data) {
    final bullets = <String>[];
    final temp     = data.temp;
    final uv       = data.estimatedUVIndex;
    final humidity = data.humidity;
    final wind     = data.windSpeed;
    final hour     = DateTime.now().hour;

    // ── 1. UV INDEX GUIDANCE ──────────────────────────────────────────────
    if (uv >= 8) {
      bullets.add(
        '☀️ Very high UV (${uv.toStringAsFixed(0)}) — apply SPF 50+ and '
        'avoid direct sun between 10 AM – 4 PM.',
      );
    } else if (uv >= 6) {
      bullets.add(
        '🧴 High UV index (${uv.toStringAsFixed(0)}) — '
        'sunscreen and a wide-brimmed hat are strongly recommended.',
      );
    } else if (uv >= 3) {
      bullets.add(
        '🌤 Moderate UV (${uv.toStringAsFixed(0)}) — '
        'light sun protection is advisable if spending time outdoors.',
      );
    }

    // ── 2. TEMPERATURE FEEL ──────────────────────────────────────────────
    if (temp >= 40) {
      bullets.add(
        '🌡️ Extreme heat (${temp.toStringAsFixed(0)}°C) — '
        'stay indoors, hydrate aggressively, and avoid any outdoor exertion.',
      );
    } else if (temp >= 35) {
      bullets.add(
        '🥵 Very hot (${temp.toStringAsFixed(0)}°C) — '
        'drink plenty of water; prefer shaded or air-conditioned spaces.',
      );
    } else if (temp >= 28) {
      bullets.add(
        '😎 Warm and pleasant (${temp.toStringAsFixed(0)}°C) — '
        'great for outdoor activities if you stay hydrated.',
      );
    } else if (temp >= 18) {
      bullets.add(
        '🙂 Comfortable temperature (${temp.toStringAsFixed(0)}°C) — '
        'a light layer is all you need.',
      );
    } else if (temp >= 10) {
      bullets.add(
        '🧥 Cool weather (${temp.toStringAsFixed(0)}°C) — '
        'a warm jacket will keep you comfortable outdoors.',
      );
    } else {
      bullets.add(
        '🥶 Cold conditions (${temp.toStringAsFixed(0)}°C) — '
        'dress in heavy layers; gloves and a scarf are recommended.',
      );
    }

    // ── 3. HUMIDITY ──────────────────────────────────────────────────────
    if (humidity >= 85) {
      bullets.add(
        '💧 Very high humidity (${humidity.toStringAsFixed(0)}%) — '
        'it will feel significantly warmer than the thermometer shows.',
      );
    } else if (humidity <= 25) {
      bullets.add(
        '🏜️ Air is very dry (${humidity.toStringAsFixed(0)}% RH) — '
        'use moisturiser and drink extra fluids to prevent dehydration.',
      );
    }

    // ── 4. WIND ADVISORY ─────────────────────────────────────────────────
    if (wind >= 15) {
      bullets.add(
        '💨 Strong winds (${wind.toStringAsFixed(1)} m/s) — '
        'secure loose outdoor items and exercise caution while driving.',
      );
    } else if (wind >= 8) {
      bullets.add(
        '🌬️ Breezy (${wind.toStringAsFixed(1)} m/s) — '
        'good for natural ventilation but bring a windbreaker.',
      );
    }

    // ── 5. SPECIAL CONDITION WARNINGS ────────────────────────────────────
    switch (data.condition.state) {
      case WeatherState.stormy:
        bullets.add(
          '⛈️ Thunderstorm warning — stay indoors, keep devices charged, '
          'and avoid open fields or elevated areas.',
        );
        break;
      case WeatherState.snowy:
        bullets.add(
          '🌨️ Snowfall expected — allow extra travel time, '
          'dress in waterproof layers, and watch for icy surfaces.',
        );
        break;
      case WeatherState.foggy:
        bullets.add(
          '🌫️ Reduced visibility — use fog lights when driving '
          'and move cautiously in unfamiliar areas.',
        );
        break;
      default:
        break;
    }

    // ── 6. EVENING STUDY SESSION HINT ────────────────────────────────────
    // This is the "flavour" insight the spec requested.
    if (hour >= 18 && hour <= 22 &&
        temp >= 14 && temp <= 30 &&
        humidity < 75 &&
        data.condition.state != WeatherState.stormy) {
      bullets.add(
        '✏️ Perfect evening for an indoor study session — '
        'conditions are calm and comfortable.',
      );
    }

    return bullets.isEmpty
        ? '🌈 Conditions look fine. Have a great day!'
        : bullets.join('\n\n');
  }

  // ── UV INDEX HELPERS ─────────────────────────────────────────────────────
  /// Returns a category label for a given UV index value.
  static String uvCategory(double uv) {
    if (uv < 3)  return 'Low';
    if (uv < 6)  return 'Moderate';
    if (uv < 8)  return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  /// Returns a traffic-light colour for the UV index.
  static Color uvColor(double uv) {
    if (uv < 3)  return const Color(0xFF4CAF50); // Green
    if (uv < 6)  return const Color(0xFFFFEB3B); // Yellow
    if (uv < 8)  return const Color(0xFFFF9800); // Orange
    if (uv < 11) return const Color(0xFFF44336); // Red
    return const Color(0xFF9C27B0);               // Purple
  }
}
