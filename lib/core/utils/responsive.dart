import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Responsive padding
  static double horizontalPadding(BuildContext context) =>
      isMobile(context) ? 16 : (isTablet(context) ? 24 : 32);

  static double verticalPadding(BuildContext context) =>
      isMobile(context) ? 16 : (isTablet(context) ? 20 : 24);

  // Responsive font sizes
  static double titleFontSize(BuildContext context) =>
      isMobile(context) ? 20 : (isTablet(context) ? 24 : 28);

  static double headingFontSize(BuildContext context) =>
      isMobile(context) ? 18 : (isTablet(context) ? 20 : 22);

  static double bodyFontSize(BuildContext context) =>
      isMobile(context) ? 14 : (isTablet(context) ? 15 : 16);

  // Grid columns
  static int gridColumns(BuildContext context) =>
      isMobile(context) ? 2 : (isTablet(context) ? 3 : 4);

  // Card/Item max width for tablet
  static double maxCardWidth(BuildContext context) =>
      isTablet(context) ? 600 : double.infinity;

  // Responsive spacing
  static double spacing(BuildContext context) =>
      isMobile(context) ? 12 : (isTablet(context) ? 16 : 20);
}
