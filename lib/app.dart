import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/map_screen.dart';
import 'data/poi_search.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';

class TasteMapApp extends StatelessWidget {
  const TasteMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '拾途',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: AppColors.warmWhite,
          secondary: AppColors.accent,
          surface: AppColors.warmWhite,
          onSurface: AppColors.ink,
        ),
        fontFamily: AppFonts.sans,
        fontFamilyFallback: const ['PingFang SC', 'Noto Sans CJK SC', 'Roboto'],
        splashFactory: NoSplash.splashFactory,
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.cardBorder),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.ink,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.cardBorder,
          ),
          thumbColor: const WidgetStatePropertyAll(Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.warmWhite,
          selectedColor: AppColors.accent,
          secondarySelectedColor: AppColors.accent,
          checkmarkColor: Colors.white,
          labelStyle: const TextStyle(color: AppColors.ink, fontSize: 13),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.ink,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      onGenerateRoute: (settings) =>
          settings.name == '/place' && settings.arguments is Poi
          ? MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  MapScreen(initialPlace: settings.arguments as Poi),
            )
          : null,
      home: const MapScreen(),
    );
  }
}
