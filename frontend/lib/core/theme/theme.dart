import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Entera Clinical Minimal Design System
/// Inspired by Japanese Minimalism + Swiss Graphic Design

// ============================================
// COLOR PALETTE
// ============================================

class EnteraColors {
  EnteraColors._();

  // Primary - Japanese Red (used sparingly)
  static const Color primary = Color(0xFFD00000);
  static const Color primaryLight = Color(0xFFFF5A36);
  static const Color primaryDark = Color(0xFF9B0000);

  // Secondary - Blue (for informational elements)
  static const Color secondary = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF42A5F5);
  static const Color secondaryDark = Color(0xFF0D47A1);

  // Backgrounds
  static const Color background = Color(0xFFFAFAFA); // Off-white/Paper
  static const Color surface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color surfaceAlt = Color(0xFFF5F5F5); // Input fields

  // Text
  static const Color textPrimary = Color(0xFF121212);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFB00020);

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Risk levels
  static const Color riskNone = Color(0xFF4CAF50);
  static const Color riskLow = Color(0xFF8BC34A);
  static const Color riskMedium = Color(0xFFFFC107);
  static const Color riskHigh = Color(0xFFD00000);
}

// ============================================
// TYPOGRAPHY
// ============================================

class EnteraTypography {
  EnteraTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      // Display - Large headlines
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: EnteraColors.textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: EnteraColors.textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),

      // Headline - Section headers
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),

      // Title - Card titles
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: EnteraColors.textPrimary,
      ),

      // Body - Content text
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: EnteraColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: EnteraColors.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: EnteraColors.textSecondary,
      ),

      // Label - Buttons, chips
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: EnteraColors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: EnteraColors.textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: EnteraColors.textTertiary,
      ),
    );
  }
}

// ============================================
// SHAPE CONSTANTS
// ============================================

class EnteraShapes {
  EnteraShapes._();

  static const double cardRadius = 12.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
  static const double chipRadius = 20.0;

  static const double borderWidth = 1.0;

  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Min touch target (Apple HIG)
  static const double minTouchTarget = 44.0;
}

// ============================================
// SHADOWS
// ============================================

class EnteraShadows {
  EnteraShadows._();

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: EnteraColors.primary.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

// ============================================
// MAIN THEME
// ============================================

class EnteraTheme {
  EnteraTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Colors
      colorScheme: const ColorScheme.light(
        primary: EnteraColors.primary,
        onPrimary: Colors.white,
        secondary: EnteraColors.primary,
        onSecondary: Colors.white,
        surface: EnteraColors.surface,
        onSurface: EnteraColors.textPrimary,
        error: EnteraColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: EnteraColors.background,

      // Typography
      textTheme: EnteraTypography.textTheme,

      // AppBar - Clean, minimal
      appBarTheme: AppBarTheme(
        backgroundColor: EnteraColors.background,
        foregroundColor: EnteraColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: EnteraColors.textPrimary,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EnteraColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EnteraShapes.buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EnteraColors.textPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: EnteraColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EnteraShapes.buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EnteraColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: EnteraColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Cards - Bento style
      cardTheme: CardThemeData(
        color: EnteraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
          side: const BorderSide(color: EnteraColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields - Filled style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EnteraColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.inputRadius),
          borderSide: const BorderSide(color: EnteraColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.inputRadius),
          borderSide: const BorderSide(color: EnteraColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.inputRadius),
          borderSide: const BorderSide(color: EnteraColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(
          color: EnteraColors.textTertiary,
          fontSize: 16,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: EnteraColors.surfaceAlt,
        selectedColor: EnteraColors.primary.withOpacity(0.1),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EnteraShapes.chipRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Bottom Navigation - Minimal, icon-only
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EnteraColors.surface,
        selectedItemColor: EnteraColors.primary,
        unselectedItemColor: EnteraColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: EnteraColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: EnteraColors.textPrimary,
        size: 24,
      ),
    );
  }
}

// ============================================
// CUSTOM WIDGETS
// ============================================

/// Bento-style card with consistent padding and styling
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? EnteraColors.surface,
      borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
            border: Border.all(color: EnteraColors.borderLight),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Primary action button with shadow
class EnteraPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const EnteraPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EnteraShapes.buttonRadius),
        boxShadow: onPressed != null ? EnteraShadows.fab : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Risk level indicator
class RiskIndicator extends StatelessWidget {
  final String level; // none, low, medium, high

  const RiskIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = switch (level.toLowerCase()) {
      'none' => EnteraColors.riskNone,
      'low' => EnteraColors.riskLow,
      'medium' => EnteraColors.riskMedium,
      'high' => EnteraColors.riskHigh,
      _ => EnteraColors.textTertiary,
    };

    final label = switch (level.toLowerCase()) {
      'none' => 'Güvenli',
      'low' => 'Düşük Risk',
      'medium' => 'Orta Risk',
      'high' => 'Yüksek Risk',
      _ => 'Bilinmiyor',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(EnteraShapes.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// THEME EXTENSION (for accessing custom colors)
// ============================================

extension EnteraThemeExtension on ThemeData {
  EnteraColorsExtension get entera => const EnteraColorsExtension();
}

class EnteraColorsExtension {
  const EnteraColorsExtension();

  Color get success => EnteraColors.success;
  Color get warning => EnteraColors.warning;
  Color get error => EnteraColors.error;
  Color get primary => EnteraColors.primary;
  Color get background => EnteraColors.background;
  Color get surface => EnteraColors.surface;
  Color get border => EnteraColors.border;
}
