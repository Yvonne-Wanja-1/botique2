import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static ScreenType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return ScreenType.desktop;
    if (width >= 700) return ScreenType.tablet;
    return ScreenType.mobile;
  }

  static bool isMobile(BuildContext context) => of(context) == ScreenType.mobile;

  static bool isDesktop(BuildContext context) => of(context) == ScreenType.desktop;

  static int gridColumns(BuildContext context) {
    return switch (of(context)) {
      ScreenType.mobile => 2,
      ScreenType.tablet => 3,
      ScreenType.desktop => 4,
    };
  }
}