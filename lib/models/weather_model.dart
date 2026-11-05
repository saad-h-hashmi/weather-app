// lib/models/weather_model.dart
// =============================================================================
// DATA MODELS — Immutable Plain-Old-Dart-Objects (PODOs).
//
// Clean Architecture rule:  The Model layer has NO dependencies on Flutter
// or on any other project layer.  It only uses Dart core libraries.
// This means every class here can be tested in isolation with pure Dart tests.
//
// Parsing strategy:
//   • factory constructors with named parameters keep construction explicit.
//   • All `num` → `double`/`int` casts are done safely via `.toDouble()` /
//     `.toInt()` so we never crash on an API that returns an int where we
//     expect a double.
//   • Null-safety: optional JSON fields use the  ?? fallback pattern.
// =============================================================================

import 'dart:math';

// ═════════════════════════════════════════════════════════════════════════════
// WEATHER STATE ENUM
// A high-level abstraction over OpenWeatherMap's 800+ condition codes.
// Used to:
//   • Pick the correct CustomPainter for the animated background.
//   • Select the matching WeatherColorTheme palette.
// ═════════════════════════════════════════════════════════════════════════════
enum WeatherState {
  sunny,        // OWM code 800
  partlyCloudy, // OWM code 801
  cloudy,       // OWM codes 802–804
  rainy,        // OWM codes 300–599
  stormy,       // OWM codes 200–299
  snowy,        // OWM codes 600–699
  foggy,        // OWM codes 700–799
}

// ═════════════════════════════════════════════════════════════════════════════
// WEATHER CONDITION
// Represents one entry from the OWM  weather[]  array.
// ═════════════════════════════════════════════════════════════════════════════
class WeatherCondition {
  final int    id;          // Numeric OWM condition code (e.g. 500 = light rain)
  final String main;        // Broad category   e.g. "Rain", "Clear", "Clouds"
  final String description; // Detailed label   e.g. "moderate rain"
  final String icon;        // OWM icon code    e.g. "10d" (day) / "10n" (night)

  const WeatherCondition({
    required this.id,
    required this.main,
    required this.description,
    required this.icon,
  });

  // ── JSON ──────────────────────────────────────────────────────────────────
  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      id:          (json['id']          as num).toInt(),
      main:        json['main']          as String,
      description: json['description']   as String,
      icon:        json['icon']          as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':          id,
        'main':        main,
        'description': description,
        'icon':        icon,
      };

  // ── DERIVED PROPERTIES ────────────────────────────────────────────────────
  /// Maps the OWM condition-id ranges to our simplified [WeatherState] enum.
  /// Reference: https://openweathermap.org/weather-conditions
  WeatherState get state {
    if (id >= 200 && id < 300) return WeatherState.stormy;       // Thunderstorm
    if (id >= 300 && id < 600) return WeatherState.rainy;        // Drizzle + Rain
    if (id >= 600 && id < 700) return WeatherState.snowy;        // Snow
    if (id >= 700 && id < 800) return WeatherState.foggy;        // Atmosphere
    if (id == 800)             return WeatherState.sunny;        // Clear sky
    if (id == 801)             return WeatherState.partlyCloudy; // Few clouds
    return WeatherState.cloudy;                                   // 802–804
  }

  /// Unicode emoji that visually represents this condition.
  /// Used as a lightweight icon when the OWM image CDN is unavailable.
  String get emoji {
    if (id >= 200 && id < 300) return '⛈️';
    if (id >= 300 && id < 400) return '🌦️';
    if (id >= 500 && id < 600) return '🌧️';
    if (id >= 600 && id < 700) return '❄️';
    if (id >= 700 && id < 800) return '🌫️';
    if (id == 800)             return '☀️';
    if (id == 801)             return '⛅';
    return '☁️';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HOURLY FORECAST
// One 3-hour time-slot from the OWM  /forecast  endpoint's  list[]  array.
// ═════════════════════════════════════════════════════════════════════════════
class HourlyForecast {
  final DateTime         time;
  final double           temp;
  final double           feelsLike;
  final double           humidity;
  final double           windSpeed;
  final WeatherCondition condition;

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
  });

  // ── JSON (OWM native format, reused for both API parsing and cache) ────────
  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final main        = json['main'] as Map<String, dynamic>;
    final wind        = json['wind'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List<dynamic>;

    return HourlyForecast(
      time: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as num).toInt() * 1000),
      temp:      (main['temp']       as num).toDouble(),
      feelsLike: (main['feels_like'] as num? ?? main['temp'] as num).toDouble(),
      humidity:  (main['humidity']   as num).toDouble(),
      windSpeed: (wind['speed']      as num? ?? 0).toDouble(),
      condition: WeatherCondition.fromJson(
          weatherList.first as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'dt': time.millisecondsSinceEpoch ~/ 1000,
        'main': {
          'temp':       temp,
          'feels_like': feelsLike,
          'humidity':   humidity,
        },
        'wind': {'speed': windSpeed},
        'weather': [condition.toJson()],
      };
}

// ═════════════════════════════════════════════════════════════════════════════
// DAILY FORECAST
// Aggregated from multiple 3-hour slots — one entry per calendar day.
// ═════════════════════════════════════════════════════════════════════════════
class DailyForecast {
  final DateTime         date;
  final double           tempMin;
  final double           tempMax;
  final WeatherCondition condition;

  const DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
  });

  Map<String, dynamic> toJson() => {
        'date':      date.millisecondsSinceEpoch,
        'tempMin':   tempMin,
        'tempMax':   tempMax,
        'condition': condition.toJson(),
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date:      DateTime.fromMillisecondsSinceEpoch(json['date']  as int),
      tempMin:   (json['tempMin'] as num).toDouble(),
      tempMax:   (json['tempMax'] as num).toDouble(),
      condition: WeatherCondition.fromJson(
          json['condition'] as Map<String, dynamic>),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WEATHER DATA
// The unified, top-level snapshot consumed by the entire UI layer.
// Built by combining the responses from OWM's  /weather  and  /forecast
// endpoints, or deserialized from the SharedPreferences cache.
// ═════════════════════════════════════════════════════════════════════════════
class WeatherData {
  final String           cityName;
  final String           country;
  final double           lat;
  final double           lon;
  final double           temp;       // Current temperature in °C
  final double           feelsLike;
  final double           tempMin;    // Today's low
  final double           tempMax;    // Today's high
  final WeatherCondition condition;
  final double           humidity;   // Relative humidity  0–100 %
  final double           windSpeed;  // m/s
  final int              windDeg;    // Meteorological degrees 0–360
  final double           visibility; // km  (OWM returns metres; we divide by 1000)
  final int              pressure;   // hPa
  final DateTime         sunrise;
  final DateTime         sunset;
  final DateTime         lastUpdated;

  /// Next 8 × 3-hour slots = first 24 hours of the forecast.
  final List<HourlyForecast> hourlyForecast;

  /// Up to 5 calendar days, each aggregated from its 3-hour slots.
  final List<DailyForecast>  dailyForecast;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.lat,
    required this.lon,
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.visibility,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
    required this.lastUpdated,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  // ── FACTORY: From live API responses ─────────────────────────────────────
  factory WeatherData.fromApiResponse({
    required Map<String, dynamic> currentJson,
    required Map<String, dynamic> forecastJson,
  }) {
    final main  = currentJson['main']  as Map<String, dynamic>;
    final wind  = currentJson['wind']  as Map<String, dynamic>? ?? {};
    final sys   = currentJson['sys']   as Map<String, dynamic>? ?? {};
    final coord = currentJson['coord'] as Map<String, dynamic>? ?? {};
    final weatherList = currentJson['weather'] as List<dynamic>;

    // ── Parse hourly forecast (first 8 slots = 24 h) ──────────────────────
    final rawList   = forecastJson['list'] as List<dynamic>;
    final hourlyList = rawList
        .take(8)
        .map((item) => HourlyForecast.fromJson(item as Map<String, dynamic>))
        .toList();

    // ── Aggregate daily forecast from 3-hour slots ────────────────────────
    // Group all slots by 'YYYY-M-D' date key.
    final grouped = <String, List<HourlyForecast>>{};
    for (final item in rawList) {
      final slot = HourlyForecast.fromJson(item as Map<String, dynamic>);
      final key  = '${slot.time.year}-${slot.time.month}-${slot.time.day}';
      grouped.putIfAbsent(key, () => []).add(slot);
    }

    // Take up to 5 days; find min/max temperature and the noon-representative
    // condition for each day.
    final dailyList = grouped.entries.take(5).map((entry) {
      final slots   = entry.value;
      final minTemp = slots.map((s) => s.temp).reduce(min);
      final maxTemp = slots.map((s) => s.temp).reduce(max);
      final noon    = slots.reduce((a, b) =>
          (a.time.hour - 12).abs() < (b.time.hour - 12).abs() ? a : b);
      return DailyForecast(
        date:      slots.first.time,
        tempMin:   minTemp,
        tempMax:   maxTemp,
        condition: noon.condition,
      );
    }).toList();

    return WeatherData(
      cityName:    currentJson['name']                        as String? ?? 'Unknown',
      country:     sys['country']                             as String? ?? '',
      lat:         (coord['lat']                              as num? ?? 0).toDouble(),
      lon:         (coord['lon']                              as num? ?? 0).toDouble(),
      temp:        (main['temp']                              as num).toDouble(),
      feelsLike:   (main['feels_like']                        as num).toDouble(),
      tempMin:     (main['temp_min']                          as num).toDouble(),
      tempMax:     (main['temp_max']                          as num).toDouble(),
      condition:   WeatherCondition.fromJson(weatherList.first as Map<String, dynamic>),
      humidity:    (main['humidity']                          as num).toDouble(),
      windSpeed:   (wind['speed']                             as num? ?? 0).toDouble(),
      windDeg:     (wind['deg']                               as num? ?? 0).toInt(),
      // OWM returns visibility in metres; convert to kilometres for display.
      visibility:  ((currentJson['visibility']                as num? ?? 10000).toDouble()) / 1000,
      pressure:    (main['pressure']                          as num? ?? 1013).toInt(),
      sunrise:     DateTime.fromMillisecondsSinceEpoch(
                       ((sys['sunrise'] as num? ?? 0).toInt()) * 1000),
      sunset:      DateTime.fromMillisecondsSinceEpoch(
                       ((sys['sunset']  as num? ?? 0).toInt()) * 1000),
      lastUpdated:  DateTime.now(),
      hourlyForecast: hourlyList,
      dailyForecast:  dailyList,
    );
  }

  // ── UV INDEX ESTIMATION ──────────────────────────────────────────────────
  // The OWM free tier does not expose a UV endpoint.
  // We estimate UV from the condition type and the current hour of day.
  // This is clearly labelled as an estimate in the UI.
  double get estimatedUVIndex {
    final hour    = lastUpdated.hour;
    final isPeak  = hour >= 10 && hour <= 16;
    final isMidDay = hour >= 11 && hour <= 14;

    switch (condition.state) {
      case WeatherState.sunny:
        return isMidDay ? 9.0 : (isPeak ? 6.0 : 2.0);
      case WeatherState.partlyCloudy:
        return isMidDay ? 6.0 : (isPeak ? 4.0 : 1.5);
      case WeatherState.cloudy:
        return isMidDay ? 3.0 : 1.0;
      case WeatherState.rainy:
      case WeatherState.stormy:
      case WeatherState.foggy:
        return 1.0;
      case WeatherState.snowy:
        // Snow surface reflects UV significantly (albedo effect).
        return isMidDay ? 4.0 : 2.0;
    }
  }

  // ── SERIALISATION (for SharedPreferences cache) ──────────────────────────
  Map<String, dynamic> toJson() => {
        'cityName':       cityName,
        'country':        country,
        'lat':            lat,
        'lon':            lon,
        'temp':           temp,
        'feelsLike':      feelsLike,
        'tempMin':        tempMin,
        'tempMax':        tempMax,
        'condition':      condition.toJson(),
        'humidity':       humidity,
        'windSpeed':      windSpeed,
        'windDeg':        windDeg,
        'visibility':     visibility,
        'pressure':       pressure,
        'sunrise':        sunrise.millisecondsSinceEpoch,
        'sunset':         sunset.millisecondsSinceEpoch,
        'lastUpdated':    lastUpdated.millisecondsSinceEpoch,
        'hourlyForecast': hourlyForecast.map((h) => h.toJson()).toList(),
        'dailyForecast':  dailyForecast.map((d) => d.toJson()).toList(),
      };

  factory WeatherData.fromCacheJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName:    json['cityName']    as String,
      country:     json['country']     as String,
      lat:         (json['lat']        as num).toDouble(),
      lon:         (json['lon']        as num).toDouble(),
      temp:        (json['temp']       as num).toDouble(),
      feelsLike:   (json['feelsLike']  as num).toDouble(),
      tempMin:     (json['tempMin']    as num).toDouble(),
      tempMax:     (json['tempMax']    as num).toDouble(),
      condition:   WeatherCondition.fromJson(json['condition'] as Map<String, dynamic>),
      humidity:    (json['humidity']   as num).toDouble(),
      windSpeed:   (json['windSpeed']  as num).toDouble(),
      windDeg:     (json['windDeg']    as num).toInt(),
      visibility:  (json['visibility'] as num).toDouble(),
      pressure:    (json['pressure']   as num).toInt(),
      sunrise:     DateTime.fromMillisecondsSinceEpoch(json['sunrise']     as int),
      sunset:      DateTime.fromMillisecondsSinceEpoch(json['sunset']      as int),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
      hourlyForecast: (json['hourlyForecast'] as List<dynamic>)
          .map((h) => HourlyForecast.fromJson(h as Map<String, dynamic>))
          .toList(),
      dailyForecast: (json['dailyForecast'] as List<dynamic>)
          .map((d) => DailyForecast.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
