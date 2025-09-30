import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: const Color(0xff2ECC71),
    surfaceDim: const Color(0xff000000),
    surfaceContainer: const Color(0xffffffff),
  ),
  textTheme: TextTheme(
    bodyLarge: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w500),
    bodySmall: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w400),
  ),
);
