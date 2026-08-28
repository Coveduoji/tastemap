import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';

class TasteMapApp extends StatelessWidget {
  const TasteMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TasteMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.ink,
          onPrimary: AppColors.warmWhite,
          secondary: AppColors.terracotta,
          surface: AppColors.warmWhite,
          onSurface: AppColors.ink,
        ),
        fontFamily: AppFonts.sans,
        splashFactory: InkRipple.splashFactory,
      ),
      home: const MapScreen(),
    );
  }
}
