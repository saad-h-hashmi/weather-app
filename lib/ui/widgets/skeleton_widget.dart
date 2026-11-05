// lib/ui/widgets/skeleton_widget.dart
// =============================================================================
// SKELETON LOADER — Shimmer-animated placeholder shown while data loads.
//
// Why skeletons instead of a spinner?
//   Skeleton screens feel faster because they communicate the SHAPE of the
//   incoming content.  The user's brain starts to anticipate the layout
//   before the data arrives, so the perceived wait time is shorter.
//
// Design rule: every skeleton block mirrors the approximate shape and size of
// the real widget it will be replaced by.  This makes the transition from
// "loading" to "loaded" feel seamless rather than jarring.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonWidget extends StatelessWidget {
  const SkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // These two colours create the shimmer sweep animation.
      // Semi-transparent on a dark background for a glowing-embers feel.
      baseColor:      Colors.white.withOpacity(0.10),
      highlightColor: Colors.white.withOpacity(0.28),
      child: SingleChildScrollView(
        // Non-scrollable so shimmer fills the screen without user interaction
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Location row ─────────────────────────────────────────
              _Box(width: 160, height: 18, r: 9),
              const SizedBox(height: 14),

              // ── Giant temperature number ──────────────────────────────
              _Box(width: 130, height: 80, r: 14),
              const SizedBox(height: 10),

              // ── Condition label ───────────────────────────────────────
              _Box(width: 200, height: 20, r: 10),
              const SizedBox(height: 6),
              _Box(width: 150, height: 14, r: 7),

              const SizedBox(height: 28),

              // ── 24-hour chart card ────────────────────────────────────
              _Box(width: double.infinity, height: 185, r: 20),

              const SizedBox(height: 16),

              // ── Insights card ─────────────────────────────────────────
              _Box(width: double.infinity, height: 110, r: 20),

              const SizedBox(height: 16),

              // ── Details 2-column grid (3 rows) ────────────────────────
              for (int i = 0; i < 3; i++) ...[
                Row(
                  children: [
                    Expanded(child: _Box(height: 78, r: 16)),
                    const SizedBox(width: 12),
                    Expanded(child: _Box(height: 78, r: 16)),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 4),

              // ── 5-day forecast rows ───────────────────────────────────
              for (int i = 0; i < 5; i++) ...[
                _Box(width: double.infinity, height: 56, r: 16),
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A filled rounded rectangle used as a single skeleton placeholder block.
class _Box extends StatelessWidget {
  final double? width;
  final double  height;
  final double  r; // border radius

  const _Box({this.width, required this.height, this.r = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer.fromColors re-colours all opaque-white descendants.
        color:        Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}
