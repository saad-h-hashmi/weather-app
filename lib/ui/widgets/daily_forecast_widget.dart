// lib/ui/widgets/daily_forecast_widget.dart
// =============================================================================
// 5-DAY DAILY FORECAST — A vertical stack of glass cards.
//
// Each card (row) shows:
//   • Day name (Today / Tomorrow / Mon etc.)
//   • Condition emoji
//   • Condition description (truncated with ellipsis)
//   • Low temperature
//   • Mini linear bar proportional to the day's temperature range
//   • High temperature
//
// The temperature range bar gives an at-a-glance sense of how wide the
// day's swing is — a heatwave day has a very short bar (narrow swing)
// while a transitional spring day has a wider bar.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_model.dart';
import '../../providers/weather_provider.dart';
import '../../utils/weather_theme.dart';
import '../../utils/weather_helpers.dart';
import 'glass_card.dart';

class DailyForecastWidget extends StatelessWidget {
  final WeatherData       data;
  final WeatherColorTheme theme;

  const DailyForecastWidget({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final daily    = data.dailyForecast;
    if (daily.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: theme.textSecondary.withOpacity(0.75),
                  size:  14,
                ),
                const SizedBox(width: 6),
                Text(
                  '5-Day Forecast',
                  style: TextStyle(
                    color:       theme.textSecondary.withOpacity(0.75),
                    fontSize:    12.5,
                    fontWeight:  FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Day cards ─────────────────────────────────────────────────
          ...daily.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayCard(
                forecast: entry.value,
                isFirst:  entry.key == 0,
                theme:    theme,
                provider: provider,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual day row ─────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final DailyForecast     forecast;
  final bool              isFirst;
  final WeatherColorTheme theme;
  final WeatherProvider   provider;

  const _DayCard({
    required this.forecast,
    required this.isFirst,
    required this.theme,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final lo = provider.displayTemp(forecast.tempMin);
    final hi = provider.displayTemp(forecast.tempMax);

    return GlassCard(
      theme:   theme,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // Day name — "Today" is accented to stand out
          SizedBox(
            width: 80,
            child: Text(
              WeatherHelpers.formatDay(forecast.date),
              style: TextStyle(
                color:      isFirst ? theme.accent : theme.textPrimary,
                fontSize:   13.5,
                fontWeight: isFirst
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),

          // Emoji icon
          Text(
            forecast.condition.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),

          // Condition description — shrinks to fit available space
          Expanded(
            child: Text(
              _capitalize(forecast.condition.description),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:    theme.textSecondary.withOpacity(0.80),
                fontSize: 12.5,
              ),
            ),
          ),

          // Low temp
          Text(
            '${lo.toStringAsFixed(0)}°',
            style: TextStyle(
              color:    theme.textSecondary.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),

          // Temperature range bar
          // Width is fixed; fill fraction = (max - min) / 20, capped at 1.
          // 20°C is an arbitrary "wide swing" reference — anything bigger
          // still fills the bar, just doesn't overflow it.
          SizedBox(
            width: 46,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((forecast.tempMax - forecast.tempMin) / 20)
                    .clamp(0.05, 1.0),
                minHeight:        4,
                backgroundColor:  Colors.white.withOpacity(0.12),
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.accent.withOpacity(0.78)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // High temp
          Text(
            '${hi.toStringAsFixed(0)}°',
            style: TextStyle(
              color:      theme.textPrimary,
              fontSize:   13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
