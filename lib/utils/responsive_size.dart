import 'package:flutter/material.dart';

class ResponsiveSize {
  static double width(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double height(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  static double fontSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375; // базовая ширина для iPhone X
    return size * scale;
  }

  static double iconSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375;
    return size * scale;
  }

  static EdgeInsets padding(
      BuildContext context, {
        double horizontal = 0,
        double vertical = 0,
        double? all,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375;

    if (all != null) {
      return EdgeInsets.all(all * scale);
    }

    return EdgeInsets.symmetric(
      horizontal: horizontal * scale,
      vertical: vertical * scale,
    );
  }

  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / 375;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getResponsiveValue({
    required BuildContext context,
    required double small,
    double? medium,
    double? large,
  }) {
    if (isLargeScreen(context)) {
      return large ?? medium ?? small;
    }

    if (isMediumScreen(context)) {
      return medium ?? small;
    }

    return small;
  }
}
