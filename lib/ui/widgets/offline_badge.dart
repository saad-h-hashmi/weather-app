// lib/ui/widgets/offline_badge.dart
// =============================================================================
// OFFLINE BADGE — A non-intrusive indicator that the app is showing cached data.
//
// Design decisions:
//   • Small and positioned at the top so it does not obscure any content.
//   • Orange colour signals "warning" without triggering "error" anxiety.
//   • A pulsing dot reinforces the "limited connectivity" message.
//   • Shown only when WeatherProvider.isOffline == true.
// =============================================================================

import 'package:flutter/material.dart';

class OfflineBadge extends StatefulWidget {
  const OfflineBadge({super.key});

  @override
  State<OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends State<OfflineBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    // Slow fade in/out for the indicator dot
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned is valid here because OfflineBadge is a direct child of
    // the Stack inside HomeScreen.
    return Positioned(
      top:   10,
      left:  0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color:        const Color(0xDD1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(
              color: Colors.orange.withOpacity(0.55),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing status dot
              FadeTransition(
                opacity: _opacity,
                child: Container(
                  width:      7,
                  height:     7,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Offline Mode — Showing Cached Data',
                style: TextStyle(
                  color:      Colors.orange,
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
