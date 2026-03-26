import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  Paleta constante — no se usa directamente
//  en widgets, usa FinPaColors extension
// ─────────────────────────────────────────────
abstract final class _Light {
  static const scaffoldBg  = Color(0xFFF5F6FA);
  static const surface     = Color(0xFFFFFFFF);
  static const cardBg      = Color(0xFFF0F2F8);
  static const border      = Color(0xFFE2E6F0);
  static const primary     = Color(0xFF3B5BDB);
  static const onPrimary   = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1F36);
  static const textSecond  = Color(0xFF6B7280);
  static const muted       = Color(0xFF9CA3AF);
  static const income      = Color(0xFF059669);
  static const expense     = Color(0xFFDC2626);
  static const warning     = Color(0xFFD97706);
}

abstract final class _Dark {
  static const scaffoldBg  = Color(0xFF0A0D14);
  static const surface     = Color(0xFF0F1320);
  static const cardBg      = Color(0xFF141928);
  static const border      = Color(0xFF1E2840);
  static const primary     = Color(0xFF3B5BDB);
  static const onPrimary   = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFE8EEFF);
  static const textSecond  = Color(0xFF8892B0);
  static const muted       = Color(0xFF4A5580);
  static const income      = Color(0xFF34D399);
  static const expense     = Color(0xFFF87171);
  static const warning     = Color(0xFFFBBF24);
}

// ─────────────────────────────────────────────
//  ThemeExtension — colores semánticos custom
//  Uso en widget:
//    final c = Theme.of(context).extension<FinPaColors>()!;
// ─────────────────────────────────────────────
class FinPaColors extends ThemeExtension<FinPaColors> {
  final Color income;
  final Color expense;
  final Color warning;
  final Color cardBg;
  final Color border;
  final Color muted;

  const FinPaColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.cardBg,
    required this.border,
    required this.muted,
  });

  static const light = FinPaColors(
    income:  _Light.income,
    expense: _Light.expense,
    warning: _Light.warning,
    cardBg:  _Light.cardBg,
    border:  _Light.border,
    muted:   _Light.muted,
  );

  static const dark = FinPaColors(
    income:  _Dark.income,
    expense: _Dark.expense,
    warning: _Dark.warning,
    cardBg:  _Dark.cardBg,
    border:  _Dark.border,
    muted:   _Dark.muted,
  );

  @override
  FinPaColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? cardBg,
    Color? border,
    Color? muted,
  }) =>
      FinPaColors(
        income:  income  ?? this.income,
        expense: expense ?? this.expense,
        warning: warning ?? this.warning,
        cardBg:  cardBg  ?? this.cardBg,
        border:  border  ?? this.border,
        muted:   muted   ?? this.muted,
      );

  @override
  FinPaColors lerp(FinPaColors? other, double t) {
    if (other == null) return this;
    return FinPaColors(
      income:  Color.lerp(income,  other.income,  t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardBg:  Color.lerp(cardBg,  other.cardBg,  t)!,
      border:  Color.lerp(border,  other.border,  t)!,
      muted:   Color.lerp(muted,   other.muted,   t)!,
    );
  }
}

// ─────────────────────────────────────────────
//  AppTheme
// ─────────────────────────────────────────────
abstract final class AppTheme {
  static TextTheme _textTheme(Color bodyColor, Color displayColor) =>
      GoogleFonts.interTextTheme().apply(
        bodyColor: bodyColor,
        displayColor: displayColor,
      );

  // ── LIGHT ────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        extensions: const [FinPaColors.light],
        textTheme: _textTheme(_Light.textPrimary, _Light.textPrimary),

        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary:              _Light.primary,
          onPrimary:            _Light.onPrimary,
          primaryContainer:     Color(0xFFDEE5FF),
          onPrimaryContainer:   Color(0xFF001258),
          secondary:            Color(0xFF4361EE),
          onSecondary:          Color(0xFFFFFFFF),
          secondaryContainer:   Color(0xFFE0E7FF),
          onSecondaryContainer: Color(0xFF001258),
          tertiary:             _Light.income,
          onTertiary:           Color(0xFFFFFFFF),
          tertiaryContainer:    Color(0xFFD1FAE5),
          onTertiaryContainer:  Color(0xFF002114),
          error:                _Light.expense,
          onError:              Color(0xFFFFFFFF),
          errorContainer:       Color(0xFFFFDAD6),
          onErrorContainer:     Color(0xFF410002),
          surface:              _Light.surface,
          onSurface:            _Light.textPrimary,
          surfaceContainerHighest: _Light.cardBg,
          onSurfaceVariant:     _Light.textSecond,
          outline:              _Light.border,
          outlineVariant:       _Light.border,
          shadow:               Color(0xFF000000),
          scrim:                Color(0xFF000000),
          inverseSurface:       _Light.textPrimary,
          onInverseSurface:     _Light.scaffoldBg,
          inversePrimary:       Color(0xFFB8C3FF),
        ),

        scaffoldBackgroundColor: _Light.scaffoldBg,

        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _Light.scaffoldBg,
          foregroundColor: _Light.textPrimary,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _Light.textPrimary,
          ),
          iconTheme: const IconThemeData(color: _Light.textPrimary),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: _Light.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _Light.border),
          ),
          margin: EdgeInsets.zero,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _Light.surface,
          hintStyle: GoogleFonts.inter(
            color: _Light.muted,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Light.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Light.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Light.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Light.expense),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _Light.primary,
            foregroundColor: _Light.onPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _Light.primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: _Light.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _Light.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _Light.primary.withAlpha(26),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? _Light.primary : _Light.textSecond,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? _Light.primary : _Light.textSecond,
              size: 22,
            );
          }),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _Light.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: _Light.border,
          thickness: 1,
          space: 0,
        ),

        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // ── DARK ─────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const [FinPaColors.dark],
        textTheme: _textTheme(_Dark.textPrimary, _Dark.textPrimary),

        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary:              _Dark.primary,
          onPrimary:            _Dark.onPrimary,
          primaryContainer:     Color(0xFF1E2D78),
          onPrimaryContainer:   Color(0xFFDEE5FF),
          secondary:            Color(0xFF7B8FF5),
          onSecondary:          Color(0xFF001258),
          secondaryContainer:   Color(0xFF1E2D78),
          onSecondaryContainer: Color(0xFFDEE5FF),
          tertiary:             _Dark.income,
          onTertiary:           Color(0xFF003822),
          tertiaryContainer:    Color(0xFF00522F),
          onTertiaryContainer:  Color(0xFFD1FAE5),
          error:                _Dark.expense,
          onError:              Color(0xFF690005),
          errorContainer:       Color(0xFF93000A),
          onErrorContainer:     Color(0xFFFFDAD6),
          surface:              _Dark.surface,
          onSurface:            _Dark.textPrimary,
          surfaceContainerHighest: _Dark.cardBg,
          onSurfaceVariant:     _Dark.textSecond,
          outline:              _Dark.border,
          outlineVariant:       _Dark.border,
          shadow:               Color(0xFF000000),
          scrim:                Color(0xFF000000),
          inverseSurface:       _Dark.textPrimary,
          onInverseSurface:     _Dark.scaffoldBg,
          inversePrimary:       Color(0xFF3B5BDB),
        ),

        scaffoldBackgroundColor: _Dark.scaffoldBg,

        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _Dark.scaffoldBg,
          foregroundColor: _Dark.textPrimary,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _Dark.textPrimary,
          ),
          iconTheme: const IconThemeData(color: _Dark.textPrimary),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: _Dark.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _Dark.border),
          ),
          margin: EdgeInsets.zero,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _Dark.cardBg,
          hintStyle: GoogleFonts.inter(
            color: _Dark.muted,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Dark.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Dark.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Dark.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Dark.expense),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _Dark.primary,
            foregroundColor: _Dark.onPrimary,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _Dark.primary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: _Dark.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _Dark.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _Dark.primary.withAlpha(51),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? _Dark.primary : _Dark.textSecond,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? _Dark.primary : _Dark.textSecond,
              size: 22,
            );
          }),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _Dark.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: _Dark.border,
          thickness: 1,
          space: 0,
        ),

        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
