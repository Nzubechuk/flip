import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
      
  static double getPreferredWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) return 600;
    if (isTablet(context)) return 500;
    return width;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    if (isMobile(context)) return 1;
    return 2;
  }
}
