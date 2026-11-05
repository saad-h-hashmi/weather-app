// lib/main.dart
// =============================================================================
// ENTRY POINT — App bootstrap, Provider wiring, and Web Layout Shell.
//
// This file answers three architectural questions:
//   1. How is state management initialised?           → MultiProvider
//   2. How does the app look on a desktop browser?    → WebLayoutShell
//   3. How do we enable mouse-drag scrolling?         → AppScrollBehavior
// =============================================================================

import 'package:flutter/gestures.dart';  // For PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/weather_provider.dart';
import 'ui/screens/home_screen.dart';
import 'utils/app_constants.dart';

// =============================================================================
// CUSTOM SCROLL BEHAVIOR
//
// Problem: On Flutter Web, scrollable widgets (ListView, SingleChildScrollView)
// only respond to touch gestures by default.  Mouse clicks and drags — the
// primary input on a laptop — do nothing.
//
// Fix: Override MaterialScrollBehavior.dragDevices to include
// PointerDeviceKind.mouse and PointerDeviceKind.trackpad.
//
// This is applied globally via MaterialApp.scrollBehavior so it affects
// every scrollable in the widget tree, including:
//   • The main content SingleChildScrollView
//   • Any future horizontal list (e.g. hourly forecast chips)
// =============================================================================
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// =============================================================================
// MAIN
// =============================================================================
void main() {
  // Must be called before any plugin (geolocator, shared_preferences) is used.
  // It initialises the Flutter engine bindings so platform channels are ready.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

// =============================================================================
// ROOT APP WIDGET
// =============================================================================
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ── PROVIDER REGISTRATION ──────────────────────────────────────────
      // WeatherProvider is registered here so it is available to the entire
      // widget tree.  Using create: (_) => WeatherProvider() means a fresh
      // instance is created lazily when first accessed.
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: MaterialApp(
        title:                    AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // ── MOUSE-DRAG SCROLLING ────────────────────────────────────────
        scrollBehavior: AppScrollBehavior(),

        // ── BASE THEME ──────────────────────────────────────────────────
        // We only define a seed so Material 3 colour generation works.
        // The actual colours in the UI come from WeatherColorTheme, not
        // from this ThemeData — so changing the seed has little visual effect.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor:  const Color(0xFF4A90E2),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),

        home: const WebLayoutShell(),
      ),
    );
  }
}

// =============================================================================
// WEB LAYOUT SHELL
//
// Wraps HomeScreen in a centred, width-constrained container so the app
// renders as a premium mobile UI inside a desktop browser window.
//
// Visual anatomy:
//   ┌─────────────────────────────────────────┐  ← Browser window
//   │           (dark canvas #1A1A2E)          │
//   │   ╔══════════════════════╗               │
//   │   ║   max-width: 420px   ║  ← Phone frame │
//   │   ║                      ║               │
//   │   ║    HomeScreen here   ║               │
//   │   ║                      ║               │
//   │   ╚══════════════════════╝               │
//   └─────────────────────────────────────────┘
//
// Why 420 px?
//   420 px is the width of a large-screen smartphone (e.g. iPhone 15 Pro Max
//   at 430 CSS pixels).  It fits cleanly on a 1280px laptop display and
//   stays comfortable on 1920px monitors.
// =============================================================================
class WebLayoutShell extends StatelessWidget {
  const WebLayoutShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── CANVAS ─────────────────────────────────────────────────────────
      // A deep navy fills the browser outside the phone frame.
      // This contrasts well with every weather state's background gradient.
      backgroundColor: const Color(0xFF0D0D1A),

      body: Center(
        child: ConstrainedBox(
          // ── WIDTH CONSTRAINT ─────────────────────────────────────────
          // maxWidth = 420 enforces the mobile layout on any screen width.
          // The height is unconstrained so the phone frame is as tall as
          // the viewport.
          constraints: const BoxConstraints(maxWidth: 420),

          child: Container(
            // ── DECORATIVE SHADOW ───────────────────────────────────────
            // Two box-shadow layers:
            //   [0] A large, soft dark shadow beneath the "phone"
            //       creates the sense of depth and elevation.
            //   [1] A very thin bright top edge simulates ambient light
            //       catching the bezel.
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppConstants.shellBorderRadius),
              boxShadow: [
                BoxShadow(
                  color:       Colors.black.withOpacity(0.55),
                  blurRadius:  70,
                  spreadRadius: 8,
                  offset:      const Offset(0, 24),
                ),
                BoxShadow(
                  color:      Colors.white.withOpacity(0.06),
                  blurRadius: 1,
                  offset:     const Offset(0, -1),
                ),
              ],
            ),

            // ── CLIP ─────────────────────────────────────────────────────
            // ClipRRect clips the HomeScreen's animated background so
            // particles do not bleed outside the rounded-corner frame.
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppConstants.shellBorderRadius),
              child: const HomeScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
