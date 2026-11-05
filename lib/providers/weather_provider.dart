// lib/providers/weather_provider.dart
// =============================================================================
// WEATHER PROVIDER — The single ChangeNotifier that drives the entire UI.
//
// Data-flow:
//   initWeather()
//     │
//     ├─ Try GPS  ──────────────────────────────────────┐
//     │   Permission denied / timeout → use Lahore      │
//     │                                                  ▼
//     ├─ Fetch from OWM API (WeatherService)  ──► Cache (CacheService) → SUCCESS
//     │   Any network failure:                          │
//     │                                                  │
//     └─ Load from SharedPreferences cache  ────────────┘
//         Nothing in cache → ERROR state
//
// Why ChangeNotifier + Provider (not Bloc, Riverpod, etc.)?
//   The spec asks for Provider/ChangeNotifier explicitly.  It is also the
//   most widely taught pattern for 5th-semester coursework and requires the
//   least boilerplate to understand and explain.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/cache_service.dart';
import '../utils/app_constants.dart';

// High-level lifecycle states — the UI switches on these to decide what to render.
enum AppLoadingState { idle, loading, success, error }

class WeatherProvider extends ChangeNotifier {
  // ── SERVICES ──────────────────────────────────────────────────────────────
  final WeatherService _weatherService = WeatherService();
  final CacheService   _cacheService   = CacheService();

  // ── PRIVATE STATE ─────────────────────────────────────────────────────────
  AppLoadingState _loadingState = AppLoadingState.idle;
  WeatherData?    _weatherData;
  String          _errorMessage = '';
  bool            _isOffline    = false;
  bool            _isCelsius    = true; // Default unit preference

  // ── PUBLIC GETTERS ─────────────────────────────────────────────────────────
  AppLoadingState get loadingState => _loadingState;
  WeatherData?    get weatherData  => _weatherData;
  String          get errorMessage => _errorMessage;
  bool            get isOffline    => _isOffline;
  bool            get isCelsius    => _isCelsius;

  // Convenience booleans used directly in widget build() methods
  bool get isLoading => _loadingState == AppLoadingState.loading;
  bool get hasData   => _weatherData  != null;
  bool get hasError  => _loadingState == AppLoadingState.error;

  // ── TEMPERATURE CONVERSION ────────────────────────────────────────────────
  /// Converts a raw Celsius value to the user's selected display unit.
  /// The model ALWAYS stores temperatures in Celsius; conversion happens here.
  double displayTemp(double celsius) =>
      _isCelsius ? celsius : (celsius * 9 / 5) + 32;

  /// The unit symbol matching the current preference.
  String get unitSymbol => _isCelsius ? '°C' : '°F';

  /// Toggles between Celsius and Fahrenheit.
  /// Calling notifyListeners() causes all watching widgets to rebuild,
  /// which triggers the AnimatedSwitcher transitions in WeatherHeaderWidget.
  void toggleUnit() {
    _isCelsius = !_isCelsius;
    notifyListeners();
  }

  // ── INIT ──────────────────────────────────────────────────────────────────
  /// Entry point — called once from HomeScreen.initState().
  ///
  /// The full 4-step fallback chain:
  ///   1. Try to get the device's GPS coordinates.
  ///   2. If GPS is denied / unavailable, fall through to Lahore defaults.
  ///   3. Fetch fresh data from OWM API using the resolved coordinates.
  ///   4. If network fails, load from SharedPreferences cache.
  ///   5. If cache is also empty → show error screen.
  Future<void> initWeather() async {
    _setLoadingState(AppLoadingState.loading);

    try {
      double lat       = AppConstants.defaultLat;
      double lon       = AppConstants.defaultLon;
      bool   usingGps  = false;

      // ── STEP 1 & 2: GPS with graceful fallback ─────────────────────────
      try {
        final position = await _getDeviceLocation();
        lat      = position.latitude;
        lon      = position.longitude;
        usingGps = true;
        debugPrint('📍 GPS acquired: $lat, $lon');
      } catch (e) {
        // Covers: permission denied, service disabled, timeout.
        // This is expected behaviour when the instructor clicks "Block" in Chrome.
        debugPrint('⚠️  Location unavailable ($e). Defaulting to Lahore.');
      }

      // ── STEP 3: Fetch from network ────────────────────────────────────
      final freshData = usingGps
          ? await _weatherService.fetchWeatherByCoords(lat: lat, lon: lon)
          : await _weatherService.fetchWeatherByCity(AppConstants.defaultCity);

      // Persist a fresh copy to the cache for future offline use.
      await _cacheService.saveWeatherData(freshData);

      _weatherData = freshData;
      _isOffline   = false;
      _errorMessage = '';
      _setLoadingState(AppLoadingState.success);
    } catch (e) {
      // ── STEP 4: Network failed — try the cache ────────────────────────
      debugPrint('❌ Network error: $e — attempting cache load…');
      final cached = await _cacheService.loadCachedData();

      if (cached != null) {
        _weatherData  = cached;
        _isOffline    = true;
        _errorMessage = '';
        _setLoadingState(AppLoadingState.success);
        debugPrint('📦 Cache loaded for ${cached.cityName}');
      } else {
        // ── STEP 5: Nothing available — surface the error ──────────────
        _errorMessage = _friendlyError(e.toString());
        _setLoadingState(AppLoadingState.error);
      }
    }
  }

  /// Re-runs the full initWeather() flow.  Attached to the pull-to-refresh
  /// gesture and the "Retry" button on the error screen.
  Future<void> refresh() => initWeather();

  // ── PRIVATE: GEOLOCATION ──────────────────────────────────────────────────
  /// Requests the device's current position with a 10-second timeout.
  ///
  /// On Flutter Web, this triggers the Chrome "Allow / Block" location
  /// permission dialog.  If the user clicks "Block", geolocator throws a
  /// LocationPermission.denied exception which we catch in initWeather().
  Future<Position> _getDeviceLocation() async {
    // On web, isLocationServiceEnabled() typically returns true even before
    // the user has been asked — the browser handles the service check itself.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on this device.');
    }

    // Check the current permission state without showing a dialog.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Show the browser's permission dialog.
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied by user.');
    }

    // Fetch position; if the browser takes > 10 s, throw TimeoutException.
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low, // Fast and sufficient for weather
    ).timeout(const Duration(seconds: 10));
  }

  // ── PRIVATE: HELPERS ──────────────────────────────────────────────────────
  void _setLoadingState(AppLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  /// Converts a raw exception string into a readable message for the error UI.
  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('Network error')) {
      return 'No internet connection and no cached data found.\n'
             'Please connect to Wi-Fi and tap Retry.';
    }
    if (raw.contains('401') || raw.contains('Invalid API key')) {
      return 'Invalid API key.\nPlease update AppConstants.owmApiKey '
             'with your OpenWeatherMap API key and restart.';
    }
    if (raw.contains('TimeoutException')) {
      return 'Request timed out. Check your connection and try again.';
    }
    return 'Something went wrong.\n$raw';
  }
}
