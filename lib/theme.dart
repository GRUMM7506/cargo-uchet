import 'package:flutter/material.dart';

const bodyFont = 'NotoSans';
const displayFont = 'Montserrat';

/// Смысловые цвета (доход / расход / долг), разные для светлой и тёмной темы.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color income;
  final Color incomeBg;
  final Color expense;
  final Color expenseBg;
  final Color debt;
  final Color debtBg;
  final Color muted;

  const AppColors({
    required this.income,
    required this.incomeBg,
    required this.expense,
    required this.expenseBg,
    required this.debt,
    required this.debtBg,
    required this.muted,
  });

  static const light = AppColors(
    income: Color(0xFF14874A),
    incomeBg: Color(0xFFE3F5EA),
    expense: Color(0xFFD13A3A),
    expenseBg: Color(0xFFFCE8E8),
    debt: Color(0xFFD9650B),
    debtBg: Color(0xFFFFF0E1),
    muted: Color(0xFF6E7681),
  );

  static const dark = AppColors(
    income: Color(0xFF5BD68E),
    incomeBg: Color(0xFF16321F),
    expense: Color(0xFFFF7D7D),
    expenseBg: Color(0xFF3A1D1D),
    debt: Color(0xFFFFA45C),
    debtBg: Color(0xFF3A2614),
    muted: Color(0xFF98A1AC),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      incomeBg: Color.lerp(incomeBg, other.incomeBg, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseBg: Color.lerp(expenseBg, other.expenseBg, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      debtBg: Color.lerp(debtBg, other.debtBg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Крупные цифры сумм — шрифтом Montserrat.
TextStyle amountStyle(double size, {Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ThemeData buildTheme(Brightness brightness, Color seed) {
  final dark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  if (dark) {
    scheme = scheme.copyWith(
      surface: const Color(0xFF111418),
      surfaceContainerLowest: const Color(0xFF0B0D10),
      surfaceContainerLow: const Color(0xFF171B20),
      surfaceContainer: const Color(0xFF1B2026),
      surfaceContainerHigh: const Color(0xFF222830),
      surfaceContainerHighest: const Color(0xFF2A313A),
    );
  } else {
    scheme = scheme.copyWith(
      surface: const Color(0xFFF5F6F9),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFEFF1F5),
      surfaceContainerHigh: const Color(0xFFE8EBF0),
      surfaceContainerHighest: const Color(0xFFE1E5EB),
    );
  }

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness, fontFamily: bodyFont);
  final tt = base.textTheme;
  TextTheme display(TextTheme t) => t.copyWith(
        displaySmall: t.displaySmall?.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w700),
        headlineLarge: t.headlineLarge?.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w700),
        headlineMedium: t.headlineMedium?.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w700),
        headlineSmall: t.headlineSmall?.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w700),
        titleLarge: t.titleLarge?.copyWith(fontFamily: displayFont, fontWeight: FontWeight.w700, fontSize: 19),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );

  final radius = BorderRadius.circular(16);
  final outline = scheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.55);

  return base.copyWith(
    textTheme: display(tt),
    scaffoldBackgroundColor: scheme.surface,
    extensions: [dark ? AppColors.dark : AppColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: outline),
      ),
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.error, width: 1.6)),
      prefixIconColor: scheme.onSurfaceVariant,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: outline),
        textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600, fontSize: 15),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: bodyFont,
          fontSize: 11,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: outline),
      labelStyle: TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w500, color: scheme.onSurface),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: outline),
        textStyle: const TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.w600, fontSize: 13),
        visualDensity: VisualDensity.compact,
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(fontFamily: bodyFont, fontSize: 14.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
      subtitleTextStyle: TextStyle(fontFamily: bodyFont, fontSize: 13, color: scheme.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? const Icon(Icons.check, size: 16) : null,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
