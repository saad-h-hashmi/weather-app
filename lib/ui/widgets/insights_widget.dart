// lib/ui/widgets/insights_widget.dart
// =============================================================================
// SMART WEATHER INSIGHTS CARD
//
// This widget surfaces the output of WeatherHelpers.generateInsight() — a
// multi-bullet natural-language analysis of the current conditions.
//
// UI elements:
//   • Header with a lightbulb icon on a tinted accent background
//   • Multi-line insight text with generous line-height for readability
//   • UV index linear progress bar with colour-coded value and category label
//   • "Estimated UV" disclaimer (OWM free tier lacks a UV endpoint)
// =============================================================================

import 'package:flutter/material.dart';

import '../../models/weather_model.dart';
import '../../utils/weather_theme.dart';
import '../../utils/weather_helpers.dart';
import 'glass_card.dart';

class InsightsWidget extends StatelessWidget {
  final WeatherData       data;
  final WeatherColorTheme theme;

  const InsightsWidget({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final insight = WeatherHelpers.generateInsight(data);
    final uv      = data.estimatedUVIndex;
    final uvColor = WeatherHelpers.uvColor(uv);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        theme.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.accent,
                    size:  17,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Weather Insights',
                  style: TextStyle(
                    color:       theme.textPrimary,
                    fontSize:    14,
                    fontWeight:  FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Natural-language summary ───────────────────────────────────
            // WeatherHelpers.generateInsight() formats bullets separated by
            // double-newlines for visual breathing room.
            Text(
              insight,
              style: TextStyle(
                color:    theme.textSecondary,
                fontSize: 13.0,
                height:   1.65,
              ),
            ),

            const SizedBox(height: 16),

            // ── UV Index bar ──────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'UV Index (est.)',
                      style: TextStyle(
                        color:    theme.textSecondary.withOpacity(0.75),
                        fontSize: 11.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${uv.toStringAsFixed(1)}  ${WeatherHelpers.uvCategory(uv)}',
                      style: TextStyle(
                        color:      uvColor,
                        fontSize:   11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar: filled proportion = uv / 11 (max possible)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:     (uv / 11).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:  Colors.white.withOpacity(0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(uvColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
