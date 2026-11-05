// lib/services/cache_service.dart
// =============================================================================
// CACHE SERVICE — Offline-first persistence layer.
//
// Why cache?
//   The spec requires the app to remain functional when opened without an
//   internet connection (e.g. the instructor's laptop is in airplane mode
//   during the demo).  We save the last successful API response as a JSON
//   string in SharedPreferences after every successful network call.
//
// Cache invalidation strategy:
//   We do NOT automatically invalidate the cache — the caller (WeatherProvider)
//   always tries the network first.  The cache is only used when the network
//   call fails.  This means the data could be hours old, which is why we
//   display "Offline Mode — Showing Cached Data" alongside the timestamp.
// =============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_model.dart';
import '../utils/app_constants.dart';

class CacheService {
  // ── WRITE ──────────────────────────────────────────────────────────────────
  /// Serialises [data] to a compact JSON string and stores it together with
  /// the current Unix timestamp (in milliseconds).
  ///
  /// Both writes are performed in parallel with [Future.wait] for efficiency.
  Future<void> saveWeatherData(WeatherData data) async {
    final prefs      = await SharedPreferences.getInstance();
    final jsonString = json.encode(data.toJson());
    final nowMs      = DateTime.now().millisecondsSinceEpoch;

    await Future.wait([
      prefs.setString(AppConstants.weatherCacheKey,          jsonString),
      prefs.setInt(   AppConstants.weatherCacheTimestampKey, nowMs),
    ]);
  }

  // ── READ ───────────────────────────────────────────────────────────────────
  /// Returns the cached [WeatherData], or null if no cache exists.
  ///
  /// Returns null (instead of throwing) on parse errors so a corrupt cache
  /// never crashes the app — it is simply treated as empty.
  Future<WeatherData?> loadCachedData() async {
    try {
      final prefs      = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(AppConstants.weatherCacheKey);
      if (jsonString == null || jsonString.isEmpty) return null;

      final map = json.decode(jsonString) as Map<String, dynamic>;
      return WeatherData.fromCacheJson(map);
    } catch (_) {
      // Silently swallow parse errors — treat as "no cache".
      return null;
    }
  }

  // ── METADATA ──────────────────────────────────────────────────────────────
  /// Returns when the cache was last written, or null if it has never been set.
  Future<DateTime?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ms    = prefs.getInt(AppConstants.weatherCacheTimestampKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // ── CLEAR ──────────────────────────────────────────────────────────────────
  /// Removes all cached weather data (useful for testing or a "reset" feature).
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(AppConstants.weatherCacheKey),
      prefs.remove(AppConstants.weatherCacheTimestampKey),
    ]);
  }
}
