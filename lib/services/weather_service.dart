// lib/services/weather_service.dart
// =============================================================================
// WEATHER SERVICE — All network I/O lives in this single class.
//
// Responsibilities:
//   • Build OWM API URLs with optional CORS-proxy prefix.
//   • Fire two concurrent GET requests (/weather + /forecast) and merge them
//     into a single WeatherData object.
//   • Provide both coordinate-based and city-name-based lookups.
//   • Throw a typed WeatherApiException on any failure so the Provider can
//     decide whether to fall back to cached data.
//
// Why concurrent requests?
//   We need two OWM endpoints for the full data set.  Firing them with
//   Future.wait() cuts the total wait time roughly in half compared to
//   awaiting them sequentially.
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import '../utils/app_constants.dart';

class WeatherService {
  // ── PUBLIC API ─────────────────────────────────────────────────────────────

  /// Fetches current weather + 5-day/3-hour forecast for [lat] / [lon].
  Future<WeatherData> fetchWeatherByCoords({
    required double lat,
    required double lon,
  }) async {
    final currentUrl  = _buildUrl(
      '${AppConstants.owmBaseUrl}/weather',
      {...AppConstants.commonParams, 'lat': '$lat', 'lon': '$lon'},
    );
    final forecastUrl = _buildUrl(
      '${AppConstants.owmBaseUrl}/forecast',
      {...AppConstants.commonParams, 'lat': '$lat', 'lon': '$lon'},
    );

    // ── Concurrent fetch ────────────────────────────────────────────────────
    final results = await Future.wait([
      _get(currentUrl),
      _get(forecastUrl),
    ]);

    return WeatherData.fromApiResponse(
      currentJson:  results[0],
      forecastJson: results[1],
    );
  }

  /// Fetches weather by city name string (e.g. 'Lahore,PK').
  /// Used as the fallback when GPS coordinates are unavailable.
  Future<WeatherData> fetchWeatherByCity(String city) async {
    final currentUrl  = _buildUrl(
      '${AppConstants.owmBaseUrl}/weather',
      {...AppConstants.commonParams, 'q': city},
    );
    final forecastUrl = _buildUrl(
      '${AppConstants.owmBaseUrl}/forecast',
      {...AppConstants.commonParams, 'q': city},
    );

    final results = await Future.wait([
      _get(currentUrl),
      _get(forecastUrl),
    ]);

    return WeatherData.fromApiResponse(
      currentJson:  results[0],
      forecastJson: results[1],
    );
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// Assembles the full request URL.
  ///
  /// If [AppConstants.useCorsProxy] is true, the target URL is URL-encoded and
  /// appended to [AppConstants.corsProxyUrl].  The proxy re-issues the request
  /// from its server (which has no Same-Origin restriction) and adds
  /// Access-Control-Allow-Origin headers to the response it relays back.
  ///
  /// Example (proxy disabled):
  ///   https://api.openweathermap.org/data/2.5/weather?lat=31.55&lon=74.33&…
  ///
  /// Example (proxy enabled):
  ///   https://corsproxy.io/?https%3A%2F%2Fapi.openweathermap.org%2F…
  String _buildUrl(String endpoint, Map<String, String> params) {
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final rawUrl = '$endpoint?$queryString';
    return AppConstants.useCorsProxy
        ? '${AppConstants.corsProxyUrl}${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
  }

  /// Sends an HTTP GET to [url] and returns the decoded JSON body.
  ///
  /// Throws [WeatherApiException] on:
  ///   • Non-200 HTTP status codes
  ///   • Network-level errors (no internet, DNS failure, timeout)
  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              // Required by cors-anywhere proxy; harmless on direct calls.
              'X-Requested-With': 'XMLHttpRequest',
              'Accept':           'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw WeatherApiException(
          'Invalid API key. Check AppConstants.owmApiKey.',
          401,
        );
      } else if (response.statusCode == 404) {
        throw WeatherApiException(
          'City not found. Check the city name or coordinates.',
          404,
        );
      } else {
        throw WeatherApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    } on WeatherApiException {
      rethrow; // Re-throw typed exceptions unchanged
    } catch (e) {
      // Wrap everything else (SocketException, TimeoutException, etc.)
      throw WeatherApiException('Network error: $e', 0);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPED EXCEPTION
// Using a typed exception (rather than a generic Exception) allows the Provider
// to inspect the status code if it needs to show a specific error message
// (e.g. "invalid API key" vs "no network").
// ─────────────────────────────────────────────────────────────────────────────
class WeatherApiException implements Exception {
  final String message;
  final int    statusCode;

  const WeatherApiException(this.message, this.statusCode);

  @override
  String toString() => 'WeatherApiException($statusCode): $message';
}
