# 🌤 WeatherScope — Premium Flutter Weather Application

A production-ready Flutter weather app built for `flutter run -d chrome`.
Implements Clean Architecture, glassmorphic UI, animated weather backgrounds,
offline caching, and smart analytical insights.

> **⚠️ API key required:** the app shows no weather data until you add a free
> [OpenWeatherMap](https://openweathermap.org/api) API key in
> `lib/utils/app_constants.dart`. See **Quick Setup** below. Don't commit your real key.

---

## ⚡ Quick Setup (5 Steps)

### 1. Get a Free API Key
1. Visit **https://home.openweathermap.org/users/sign_up**
2. Verify your email
3. Go to **API Keys** tab → copy the default key
4. ⏱ Keys activate within **2 hours** of registration

### 2. Paste Your API Key
Open `lib/utils/app_constants.dart` and replace:
```dart
static const String owmApiKey = 'YOUR_API_KEY_HERE';
//                               ^^^^^^^^^^^^^^^^^^^ paste here
```

### 3. Install Dependencies
```bash
# One-time: generate the platform folders (web/, android/, ...) which are not stored in this repo
flutter create . --platforms=web

flutter pub get
```

### 4. Run in Chrome
```bash
flutter run -d chrome
```

### 5. Handle Location Permission
- **Allow** → app uses your real GPS coordinates
- **Block** → app silently falls back to **Lahore, Pakistan** (no crash)

---

## 🏗 Clean Architecture — Folder Structure

```
lib/
├── main.dart                      # App entry, Provider wiring, WebLayoutShell
│
├── models/
│   └── weather_model.dart         # PODOs — WeatherData, HourlyForecast, DailyForecast
│
├── services/
│   ├── weather_service.dart       # HTTP networking — OWM API calls
│   └── cache_service.dart         # SharedPreferences read/write
│
├── providers/
│   └── weather_provider.dart      # ChangeNotifier — all business logic
│
├── ui/
│   ├── screens/
│   │   └── home_screen.dart       # Root screen — Stack + scroll orchestration
│   └── widgets/
│       ├── animated_background.dart   # CustomPainter particle engine
│       ├── glass_card.dart            # BackdropFilter glassmorphic container
│       ├── weather_header_widget.dart # Temp + AnimatedSwitcher + unit toggle
│       ├── temp_chart_widget.dart     # fl_chart 24-h line graph
│       ├── insights_widget.dart       # Smart natural-language analysis card
│       ├── extra_details_widget.dart  # Humidity, wind, visibility grid
│       ├── daily_forecast_widget.dart # 5-day forecast rows
│       ├── skeleton_widget.dart       # Shimmer loading placeholders
│       └── offline_badge.dart         # Cached-data indicator
│
└── utils/
    ├── app_constants.dart          # All magic strings and numbers
    ├── weather_theme.dart          # Dynamic colour-harmonisation system
    └── weather_helpers.dart        # Pure utility functions
```

### Why Clean Architecture?

| Layer | Depends On | Never Depends On |
|-------|-----------|-----------------|
| `models/` | Dart core only | Flutter, services, UI |
| `services/` | models, utils | UI, providers |
| `providers/` | models, services, utils | UI widgets |
| `ui/` | providers, models, utils | services (directly) |

This means you can unit-test `WeatherData.fromApiResponse()` with a plain
`dart test` — no Flutter engine required.

---

## 🔑 Key Features Explained

### 1. Web Layout Shell (420 px constraint)
`main.dart → WebLayoutShell`

```dart
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 420),
  child: Container(
    decoration: BoxDecoration(boxShadow: [...], borderRadius: ...),
    child: ClipRRect(child: const HomeScreen()),
  ),
)
```
The `Center + ConstrainedBox` combination ensures the app maintains a phone
aspect ratio on any screen width. `ClipRRect` clips the background animations
to the rounded corners.

### 2. Mouse-Drag Scrolling
`main.dart → AppScrollBehavior`

```dart
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,    // ← This is the key addition
    PointerDeviceKind.trackpad,
  };
}
```
Applied globally via `MaterialApp(scrollBehavior: AppScrollBehavior())`.

### 3. Offline Caching
**Write path:** `WeatherProvider.initWeather()` → `CacheService.saveWeatherData()`
**Read path:** Network fails → `CacheService.loadCachedData()` → show `OfflineBadge`

The cache stores the full JSON response as a single string in
`SharedPreferences` under a versioned key. If the schema ever changes,
incrementing the key suffix (`_v2`) safely invalidates all old caches.

### 4. Parallax Background
`animated_background.dart` — each painter receives `scrollOffset`:

```dart
// Every particle y-position calculation:
final rawY = (phase + animValue * speed + scrollOffset * 0.3 / height) % 1.0;
//                                        ^^^^^^^^^^^^^^^^
//                                        30% of scroll speed = parallax depth
```

The `AnimatedBackground` listens to both its own `AnimationController` AND
the parent's `ScrollController` via `Listenable.merge([])`, so it repaints
on both animation ticks and scroll events without any `setState()` calls.

### 5. AnimatedSwitcher (C° ↔ F° transition)
`weather_header_widget.dart`

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 380),
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween(begin: 0.72, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      ),
      child: child,
    ),
  ),
  child: Text(
    key: ValueKey('${isCelsius}_${displayTemp(data.temp).toStringAsFixed(0)}'),
    '${displayTemp(data.temp).toStringAsFixed(0)}°',
  ),
)
```
The `ValueKey` must contain BOTH the unit flag and the temperature value.
If only the unit changes, the key changes → animation fires.
If data refreshes to a new temperature, the key also changes → animation fires.

### 6. Glassmorphism
`glass_card.dart`

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),  // Frost intensity
  child: Container(
    color: theme.cardFill,  // ~15% opaque white — lets blur show through
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withOpacity(0.22)), // Edge glint
    ),
  ),
)
```
Works natively in Chrome because the browser supports CSS `backdrop-filter`.

### 7. Smart Insights Engine
`weather_helpers.dart → generateInsight()`

Analyses 5 metrics in sequence:
1. **UV index** → SPF advice
2. **Temperature** → comfort assessment
3. **Humidity** → feels-like warning
4. **Wind speed** → outdoor safety
5. **Condition state** → storm/snow/fog special alerts
6. **Time of day + conditions** → "study session" hint

---

## 🎨 Dynamic Colour Themes

| Weather State | Gradient | Accent |
|--------------|----------|--------|
| ☀️ Sunny | Orange → Amber → Sky Blue | Golden Yellow |
| ⛅ Partly Cloudy | Mid Blue → Light Blue → Sky | Golden |
| ☁️ Cloudy | Dark Slate → Blue-Grey | Teal |
| 🌧 Rainy | Deep Indigo → Royal Blue → Bright Blue | Soft Blue |
| ⛈ Stormy | Near-Black → Dark Navy → Deep Purple | Electric Purple |
| ❄️ Snowy | Cold Blue → Icy Blue → Near-White | Mint Green |
| 🌫 Foggy | Dark Slate → Blue-Grey → Light Grey | Aqua |

---

## 🐛 Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Invalid API key` error screen | Paste your OWM key in `app_constants.dart` |
| CORS error in Chrome console | Set `useCorsProxy = true` in `app_constants.dart`; visit `https://cors-anywhere.herokuapp.com/corsdemo` first |
| Always shows Lahore | Expected — location permission was denied; the fallback is working correctly |
| Chart shows no data | The OWM free key needs ~2 hours to activate after registration |
| `pub get` fails | Run `flutter upgrade` then `flutter pub get` again |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.1 | OpenWeatherMap API HTTP calls |
| `provider` | ^6.1.2 | ChangeNotifier state management |
| `shared_preferences` | ^2.3.1 | JSON cache persistence |
| `geolocator` | ^11.0.0 | Browser GPS permission + position |
| `shimmer` | ^3.0.0 | Skeleton loading animation |
| `fl_chart` | ^0.68.0 | 24-hour temperature line chart |
