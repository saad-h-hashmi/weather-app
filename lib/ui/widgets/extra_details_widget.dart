// lib/ui/widgets/extra_details_widget.dart
// =============================================================================
// EXTRA DETAILS — A responsive 2-column grid of secondary weather metrics.
//
// Metrics displayed (3 rows × 2 columns):
//   Row 1: Humidity  |  Wind speed + direction
//   Row 2: Visibility  |  Pressure
//   Row 3: Sunrise  |  Sunset
//
// Each tile is a compact GlassCard with:
//   • Theme-coloured icon
//   • Metric label in secondary text
//   • Value in bold primary text
// =============================================================================

import 'package:flutter/material.dart';

import '../../models/weather_model.dart';
import '../../utils/weather_theme.dart';
import '../../utils/weather_helpers.dart';
import 'glass_card.dart';

class ExtraDetailsWidget extends StatelessWidget {
  final WeatherData       data;
  final WeatherColorTheme theme;

  const ExtraDetailsWidget({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Current Conditions',
              style: TextStyle(
                color:       theme.textSecondary.withOpacity(0.75),
                fontSize:    12.5,
                fontWeight:  FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),

          // ── Row 1: Humidity + Wind ─────────────────────────────────────
          _TileRow(
            tiles: [
              _TileData(
                icon:  Icons.water_drop_outlined,
                label: 'Humidity',
                value: '${data.humidity.toStringAsFixed(0)} %',
              ),
              _TileData(
                icon:  Icons.air_rounded,
                label: 'Wind',
                value: '${data.windSpeed.toStringAsFixed(1)} m/s  '
                       '${WeatherHelpers.windDirection(data.windDeg)}',
              ),
            ],
            theme: theme,
          ),
          const SizedBox(height: 12),

          // ── Row 2: Visibility + Pressure ──────────────────────────────
          _TileRow(
            tiles: [
              _TileData(
                icon:  Icons.visibility_outlined,
                label: 'Visibility',
                value: '${data.visibility.toStringAsFixed(1)} km',
              ),
              _TileData(
                icon:  Icons.compress_rounded,
                label: 'Pressure',
                value: '${data.pressure} hPa',
              ),
            ],
            theme: theme,
          ),
          const SizedBox(height: 12),

          // ── Row 3: Sunrise + Sunset ────────────────────────────────────
          _TileRow(
            tiles: [
              _TileData(
                icon:  Icons.wb_sunny_outlined,
                label: 'Sunrise',
                value: WeatherHelpers.formatTime(data.sunrise),
              ),
              _TileData(
                icon:  Icons.nights_stay_outlined,
                label: 'Sunset',
                value: WeatherHelpers.formatTime(data.sunset),
              ),
            ],
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ── Data container ────────────────────────────────────────────────────────────
class _TileData {
  final IconData icon;
  final String   label;
  final String   value;
  const _TileData({required this.icon, required this.label, required this.value});
}

// ── One row of two tiles ──────────────────────────────────────────────────────
class _TileRow extends StatelessWidget {
  final List<_TileData>   tiles;
  final WeatherColorTheme theme;

  const _TileRow({required this.tiles, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tiles.expand((tile) sync* {
        yield Expanded(child: _DetailTile(data: tile, theme: theme));
        if (tile != tiles.last) yield const SizedBox(width: 12);
      }).toList(),
    );
  }
}

// ── Individual metric tile ────────────────────────────────────────────────────
class _DetailTile extends StatelessWidget {
  final _TileData         data;
  final WeatherColorTheme theme;

  const _DetailTile({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      theme:   theme,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          Icon(data.icon, color: theme.accent, size: 19),
          const SizedBox(height: 7),
          Text(
            data.label,
            style: TextStyle(
              color:    theme.textSecondary.withOpacity(0.65),
              fontSize: 10.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
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
}
