// lib/ui/widgets/weather_header_widget.dart
// =============================================================================
// WEATHER HEADER — The first thing the user sees.
//
// Contains:
//   • City name + country and "last updated" timestamp
//   • Giant temperature number with AnimatedSwitcher cross-fade + scale
//   • Celsius / Fahrenheit toggle pill button
//   • Weather condition with emoji and H/L temperatures
//
// AnimatedSwitcher explanation:
//   AnimatedSwitcher watches the `key` of its child.  When the key changes
//   (either because the unit flipped or new data arrived), Flutter removes
//   the old child and inserts the new one, running the transition between them.
//   We use a custom transitionBuilder that combines:
//     • FadeTransition — cross-fade between old and new
//     • ScaleTransition — the new value "pops in" from 70% size
//   The result is a smooth, tactile feel rather than a snap-update.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/weather_model.dart';
import '../../providers/weather_provider.dart';
import '../../utils/weather_theme.dart';
import '../../utils/weather_helpers.dart';

class WeatherHeaderWidget extends StatelessWidget {
  final WeatherData       data;
  final WeatherColorTheme theme;

  const WeatherHeaderWidget({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Location + timestamp ─────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: theme.textPrimary.withOpacity(0.75),
                size:  16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${data.cityName}, ${data.country}',
                  overflow:   TextOverflow.ellipsis,
                  style: TextStyle(
                    color:       theme.textPrimary.withOpacity(0.88),
                    fontSize:    15,
                    fontWeight:  FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Pull-to-refresh hint + last-updated label
              Row(
                children: [
                  Icon(Icons.refresh_rounded,
                      color: theme.textSecondary.withOpacity(0.5), size: 13),
                  const SizedBox(width: 3),
                  Text(
                    WeatherHelpers.formatLastUpdated(data.lastUpdated),
                    style: TextStyle(
                      color:    theme.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Row 2: Giant temperature + unit toggle ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AnimatedSwitcher wrapping the temperature ────────────────
              // The ValueKey is constructed from BOTH the unit flag AND the
              // rounded temp value.  This fires the animation when either
              // the unit is toggled or the data refreshes to a new temperature.
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.72, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve:  Curves.easeOutBack,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    // When this key changes, AnimatedSwitcher runs the transition
                    key: ValueKey(
                      '${provider.isCelsius}_${provider.displayTemp(data.temp).toStringAsFixed(0)}',
                    ),
                    '${provider.displayTemp(data.temp).toStringAsFixed(0)}°',
                    style: TextStyle(
                      color:       theme.textPrimary,
                      fontSize:    90,
                      fontWeight:  FontWeight.w200,
                      height:      1.0,
                      letterSpacing: -5,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ── Unit toggle pill ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: GestureDetector(
                  onTap: provider.toggleUnit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _UnitLabel('°C', provider.isCelsius,  theme),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width:  1,
                          height: 12,
                          color:  Colors.white.withOpacity(0.35),
                        ),
                        _UnitLabel('°F', !provider.isCelsius, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Row 3: Emoji + condition description + H/L ───────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                data.condition.emoji,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(data.condition.description),
                    style: TextStyle(
                      color:      theme.textPrimary,
                      fontSize:   20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'H: ${provider.displayTemp(data.tempMax).toStringAsFixed(0)}°'
                    '   '
                    'L: ${provider.displayTemp(data.tempMin).toStringAsFixed(0)}°'
                    '   '
                    'Feels ${provider.displayTemp(data.feelsLike).toStringAsFixed(0)}°',
                    style: TextStyle(
                      color:    theme.textSecondary.withOpacity(0.85),
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Unit label helper ─────────────────────────────────────────────────────────
class _UnitLabel extends StatelessWidget {
  final String          label;
  final bool            isActive;
  final WeatherColorTheme theme;

  const _UnitLabel(this.label, this.isActive, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color:      isActive
            ? theme.textPrimary
            : theme.textSecondary.withOpacity(0.4),
        fontSize:   13,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}
