// lib/ui/widgets/temp_chart_widget.dart
// =============================================================================
// TEMPERATURE CHART — 24-hour forecast as a smooth line chart.
//
// Library: fl_chart ^0.68.0
//
// Features:
//   • Smooth Bezier curve (isCurved: true) through 8 data points (3-h intervals)
//   • Line colour uses a gradient matching the current theme accent
//   • Soft gradient area fill below the line (fade to transparent)
//   • Touch/hover tooltip shows the exact temperature and time slot
//   • Bottom-axis labels show human-friendly hour strings (e.g. "3 PM")
//   • Small dot at each data point; invisible until touched
//   • Respects the Celsius/Fahrenheit toggle via WeatherProvider
// =============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../models/weather_model.dart';
import '../../providers/weather_provider.dart';
import '../../utils/weather_theme.dart';
import '../../utils/weather_helpers.dart';
import 'glass_card.dart';

class TempChartWidget extends StatelessWidget {
  final WeatherData       data;
  final WeatherColorTheme theme;

  const TempChartWidget({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final hourly   = data.hourlyForecast;
    if (hourly.isEmpty) return const SizedBox.shrink();

    // Convert each hourly slot to a FlSpot (x = slot index, y = display temp)
    final spots = List.generate(hourly.length, (i) {
      return FlSpot(i.toDouble(), provider.displayTemp(hourly[i].temp));
    });

    // Y-axis bounds with padding so the line never touches the chart edges
    final temps   = spots.map((s) => s.y).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b) - 3;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b) + 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        theme:   theme,
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: theme.accent, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    '24-Hour Forecast',
                    style: TextStyle(
                      color:       theme.textPrimary,
                      fontSize:    13,
                      fontWeight:  FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    provider.unitSymbol,
                    style: TextStyle(
                      color:    theme.textSecondary.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── LineChart ─────────────────────────────────────────────────
            SizedBox(
              height: 145,
              child: LineChart(
                LineChartData(
                  // Disable default grid and border for a clean minimal look
                  gridData:   const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: minTemp,
                  maxY: maxTemp,

                  // ── Axis titles ──────────────────────────────────────────
                  titlesData: FlTitlesData(
                    leftTitles:  const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles:   const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles:   true,
                        reservedSize: 26,
                        interval:     1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          // Show every 2nd label to avoid crowding
                          if (idx >= hourly.length || idx % 2 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              WeatherHelpers.formatHour(hourly[idx].time),
                              style: TextStyle(
                                color:    theme.textSecondary.withOpacity(0.65),
                                fontSize: 9.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Touch / hover tooltip ────────────────────────────────
                  // On desktop Chrome, a hover over the chart line will show
                  // the tooltip at the nearest data point.
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          theme.gradientMid.withOpacity(0.92),
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx  = spot.spotIndex;
                          final slot = hourly[idx];
                          return LineTooltipItem(
                            '${provider.displayTemp(slot.temp).toStringAsFixed(1)}'
                            '${provider.unitSymbol}\n',
                            TextStyle(
                              color:      theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize:   12,
                            ),
                            children: [
                              TextSpan(
                                text: WeatherHelpers.formatHour(slot.time),
                                style: TextStyle(
                                  color:    theme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),

                  // ── Line series ──────────────────────────────────────────
                  lineBarsData: [
                    LineChartBarData(
                      spots:           spots,
                      isCurved:        true,
                      curveSmoothness: 0.32,

                      // Gradient on the LINE itself (not just the fill)
                      gradient: LinearGradient(
                        colors: [
                          theme.accent.withOpacity(0.55),
                          theme.accent,
                          theme.gradientTop.withOpacity(0.75),
                        ],
                      ),
                      barWidth: 2.5,

                      // Show dots; larger on touch via getDotPainter
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, bar, idx) =>
                            FlDotCirclePainter(
                          radius:      2.8,
                          color:       theme.accent,
                          strokeColor: Colors.white.withOpacity(0.55),
                          strokeWidth: 1.4,
                        ),
                      ),

                      // ── Gradient fill below the curve ────────────────────
                      // Fades from semi-opaque at the line down to transparent
                      // at the bottom, giving the area a "glow" effect.
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin:  Alignment.topCenter,
                          end:    Alignment.bottomCenter,
                          colors: [
                            theme.accent.withOpacity(0.32),
                            theme.accent.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
