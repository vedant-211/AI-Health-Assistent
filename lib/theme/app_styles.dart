import 'package:flutter/material.dart';

class AppStyles {
  // Moonly / Kurzgesagt Soft Dark Palette
  static const Color bgDark = Color(0xff0B0816); // Deep Space
  static const Color bgSurface = Color(0xff1A1625); // Elevated Dark Purple
  static const Color bgLight = Color(0xff2A2438); // Lighter Surface
  static const Color primaryBlue = Color(0xff8B5CF6); // Renamed conceptually to primaryViolet
  static const Color accentBlue = Color(0xffFDA4AF); // Soft glowing pink
  static const Color textMain = Color(0xffF8FAFC); // Almost white
  static const Color textSecondary = Color(0xffA78BFA); // Soft purple grey
  static const Color bgWhite = Color(0xff1A1625); // Redirect white components to surface
  static const Color greyAccent = Color(0xff4C1D95); // Deep accent tone

  // Animation Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 600);
  static const Curve animationCurve = Curves.easeInOut;

  // Spacing
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Soft Depth (Dark Shadows)
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 4),
    )
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    )
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.1),
      blurRadius: 30,
      offset: const Offset(0, 12),
      spreadRadius: -5,
    )
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 5),
    )
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.35),
      blurRadius: 30,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    )
  ];

  // Signature Identity (Subtle Dark Glows)
  static const Gradient auraBlue = RadialGradient(
    colors: [Color(0x338B5CF6), Colors.transparent], // Soft purple aura
    radius: 0.8,
  );

  static final Border glassBorder = Border.all(
    color: Colors.white.withOpacity(0.08),
    width: 1.0,
  );

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xff8B5CF6), // Vibrant purple
      Color(0xff4C1D95), // Deep purple
    ],
  );

  static final Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xff8B5CF6).withOpacity(0.15),
      const Color(0xffFDA4AF).withOpacity(0.1),
    ],
  );

  static final Gradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.05),
      Colors.white.withOpacity(0.01),
    ],
  );
}
