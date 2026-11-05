// lib/utils/app_constants.dart
// =============================================================================
// APP CONSTANTS — Single source of truth for every magic string and number.
// Centralising these here means you only need to change ONE value if, for
// example, the API endpoint or cache key format ever changes.
// =============================================================================

/// Holds all application-wide constants.
/// Private constructor prevents instantiation — use as a static namespace.
class AppConstants {
  AppConstants._();

  // ── APP IDENTITY ────────────────────────────────────────────────────────────
  static const String appName = 'WeatherScope';

  // ── OPENWEATHERMAP API ──────────────────────────────────────────────────────
  // ⚠️  IMPORTANT — ACTION REQUIRED:
  //    Replace 'YOUR_API_KEY_HERE' with your free OWM API key.
  //    Sign up at:  https://home.openweathermap.org/users/sign_up
  //    Free tier:   1,000 calls / day — plenty for testing and evaluation.
  //    The key is usually active within 2 hours of registration.
  static const String owmApiKey = 'YOUR_API_KEY_HERE';

  // Base URL for OWM free-tier endpoints (v2.5 — no subscription required)
  static const String owmBaseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Query parameters appended to every OWM API call.
  /// 'units=metric'  → all temperatures returned in Celsius.
  /// 'lang=en'       → condition descriptions in English.
  static Map<String, String> get commonParams => {
        'appid': owmApiKey,
        'units': 'metric',
        'lang': 'en',
      };

  // ── CORS PROXY ──────────────────────────────────────────────────────────────
  // Flutter Web runs inside a browser that enforces the Same-Origin Policy.
  // Normally, a cross-origin request is blocked UNLESS the target server sends
  // the 'Access-Control-Allow-Origin: *' header.
  //
  // OpenWeatherMap DOES send this header, so [useCorsProxy] defaults to FALSE.
  // If you see a "CORS error" in the Chrome DevTools console, flip it to TRUE.
  //
  // To use cors-anywhere proxy:
  //   1. Visit https://cors-anywhere.herokuapp.com/corsdemo
  //   2. Click "Request temporary access to the demo server"
  //   3. Set [useCorsProxy] = true and [corsProxyUrl] = 'https://cors-anywhere.herokuapp.com/'
  //
  // Alternative (no registration):  https://corsproxy.io/?
  static const bool useCorsProxy = false;
  static const String corsProxyUrl = 'https://corsproxy.io/?';

  // ── DEFAULT LOCATION ────────────────────────────────────────────────────────
  // These coordinates are used when the instructor denies location permission
  // in Chrome, or when the Geolocation API is unavailable.
  // Lahore, Punjab, Pakistan  (lat: 31.5497, lon: 74.3294)
  static const double defaultLat  = 31.5497;
  static const double defaultLon  = 74.3294;
  static const String defaultCity = 'Lahore,PK';

  // ── SHARED PREFERENCES CACHE KEYS ──────────────────────────────────────────
  // Versioned keys (v1 suffix) allow safe invalidation if the schema changes.
  static const String weatherCacheKey          = 'weather_cache_v1';
  static const String weatherCacheTimestampKey = 'weather_cache_ts_v1';

  // ── UI GEOMETRY ─────────────────────────────────────────────────────────────
  // Border-radius of the outer phone-frame shell in WebLayoutShell.
  static const double shellBorderRadius = 32.0;

  // Shared border-radius for all glassmorphic info cards.
  static const double cardBorderRadius  = 20.0;

  // ImageFilter.blur sigma — controls the frost intensity of glass cards.
  // 15.0 gives a strong blur without making the text behind unreadable.
  static const double cardBlurSigma     = 15.0;
}
