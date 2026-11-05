// lib/ui/screens/home_screen.dart
// =============================================================================
// HOME SCREEN — The root screen that orchestrates all widgets.
//
// Layer stack (bottom to top):
//   [0] AnimatedBackground  — full-screen, fixed position, receives scroll
//                              offset for parallax (moves at 30% scroll speed)
//   [1] SingleChildScrollView — the scrollable content column
//   [2] OfflineBadge (conditional) — non-intrusive cached-data indicator
//
// Lifecycle:
//   initState  → addPostFrameCallback → provider.initWeather()
//   The post-frame callback ensures the Provider is fully wired into the
//   widget tree before we call it — calling it synchronously in initState
//   can cause a "setState called during build" error.
//
// Parallax mechanism:
//   A single ScrollController is shared between this screen and
//   AnimatedBackground.  The background uses it as a Listenable so it
//   repaints automatically whenever the scroll position changes — no
//   setState() required, and only the CustomPaint canvas redraws.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_model.dart';
import '../../providers/weather_provider.dart';
import '../../utils/weather_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/weather_header_widget.dart';
import '../widgets/temp_chart_widget.dart';
import '../widgets/insights_widget.dart';
import '../widgets/extra_details_widget.dart';
import '../widgets/daily_forecast_widget.dart';
import '../widgets/skeleton_widget.dart';
import '../widgets/offline_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Shared between this widget and AnimatedBackground.
  // AnimatedBackground listens to it directly via Listenable.merge() in its
  // AnimatedBuilder, so the canvas repaints on every scroll tick without
  // triggering a full widget rebuild of HomeScreen.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Defer the network call to the first post-frame moment so the Provider
    // is fully available in the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().initWeather();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<WeatherProvider>();
    final data        = provider.weatherData;

    // Fall back to 'sunny' theme while loading so the background is never blank
    final weatherState = data?.condition.state ?? WeatherState.sunny;
    final theme        = WeatherColorTheme.fromState(weatherState);

    return Stack(
      children: [
        // ── LAYER 0: Animated Background ─────────────────────────────────
        // Positioned.fill keeps it behind every other layer.
        // It does NOT scroll with the foreground; the parallax effect is
        // achieved inside the CustomPainter by offsetting particles at 30%
        // of the reported scroll offset.
        Positioned.fill(
          child: AnimatedBackground(
            weatherState:     weatherState,
            theme:            theme,
            scrollController: _scrollController,
          ),
        ),

        // ── LAYER 1: Scrollable content ───────────────────────────────────
        _buildBodyContent(provider, data, theme),

        // ── LAYER 2: Offline badge ────────────────────────────────────────
        // Rendered last so it always floats on top of the content.
        if (provider.isOffline) const OfflineBadge(),
      ],
    );
  }

  // ── BODY CONTENT SWITCHER ──────────────────────────────────────────────────
  Widget _buildBodyContent(
    WeatherProvider   provider,
    WeatherData?      data,
    WeatherColorTheme theme,
  ) {
    // ── LOADING: Show shimmer skeleton ─────────────────────────────────────
    if (provider.isLoading && data == null) {
      return const SkeletonWidget();
    }

    // ── ERROR: Network failed AND no cache available ────────────────────────
    if (provider.hasError && data == null) {
      return _ErrorScreen(
        message: provider.errorMessage,
        onRetry: provider.refresh,
        theme:   theme,
      );
    }

    // ── SUCCESS: Live or cached data is available ───────────────────────────
    if (data != null) {
      // RefreshIndicator enables pull-to-refresh on mobile AND mouse-drag-to-
      // refresh on desktop Chrome (works because we enabled PointerDeviceKind
      // .mouse in AppScrollBehavior in main.dart).
      return RefreshIndicator(
        onRefresh: provider.refresh,
        color:     theme.accent,
        child: SingleChildScrollView(
          controller: _scrollController,
          // AlwaysScrollableScrollPhysics ensures the scroll view is always
          // scrollable (even if content is shorter than the screen), which is
          // required for RefreshIndicator to work correctly.
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── City, temperature, condition ──────────────────────────
              WeatherHeaderWidget(data: data, theme: theme),
              const SizedBox(height: 16),

              // ── 24-hour temperature line chart ────────────────────────
              TempChartWidget(data: data, theme: theme),
              const SizedBox(height: 16),

              // ── Smart weather insights + UV bar ───────────────────────
              InsightsWidget(data: data, theme: theme),
              const SizedBox(height: 16),

              // ── Humidity, wind, visibility, pressure, sun times ───────
              ExtraDetailsWidget(data: data, theme: theme),
              const SizedBox(height: 16),

              // ── 5-day daily forecast rows ─────────────────────────────
              DailyForecastWidget(data: data, theme: theme),

              // Extra bottom padding so the last card clears the screen
              const SizedBox(height: 36),
            ],
          ),
        ),
      );
    }

    // Idle state before initWeather() fires — show nothing (never visible
    // to the user because initWeather() is called in the same frame)
    return const SizedBox.shrink();
  }
}

// =============================================================================
// ERROR SCREEN
// Only shown when BOTH network AND cache have failed — the absolute worst case.
// =============================================================================
class _ErrorScreen extends StatelessWidget {
  final String          message;
  final VoidCallback    onRetry;
  final WeatherColorTheme theme;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cloud-off icon
            Icon(
              Icons.cloud_off_rounded,
              color: theme.textSecondary.withOpacity(0.7),
              size:  72,
            ),
            const SizedBox(height: 24),

            Text(
              'No Weather Data',
              style: TextStyle(
                color:      theme.textPrimary,
                fontSize:   22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    theme.textSecondary,
                fontSize: 13.5,
                height:   1.55,
              ),
            ),
            const SizedBox(height: 28),

            // Retry button
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color:        theme.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.accent.withOpacity(0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: theme.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color:      theme.textPrimary,
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // API key hint — helpful during evaluation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.35)),
              ),
              child: Text(
                '💡 If you see "Invalid API key", open\n'
                'lib/utils/app_constants.dart\nand replace '
                'owmApiKey with your free\nOpenWeatherMap API key.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    Colors.orange.withOpacity(0.9),
                  fontSize: 11.5,
                  height:   1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
