import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sbg_profesores/theme/app_colors.dart';

const _themePreferenceKey = 'app_is_dark_mode';

class AppThemeController extends ChangeNotifier {
  AppThemeController({required bool isDarkMode}) : _isDarkMode = isDarkMode;

  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  static Future<AppThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppThemeController(
      isDarkMode: prefs.getBool(_themePreferenceKey) ?? false,
    );
  }

  Future<void> toggleTheme() => setDarkMode(!_isDarkMode);

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, value);
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'AppThemeScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

class AppTheme {
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF8F7FF),
        surface: Colors.white,
        surfaceContainer: const Color(0xFFFFF7FF),
        onSurface: const Color(0xFF15151F),
        outline: const Color(0xFFE3E0F3),
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        scaffold: const Color(0xFF0F1220),
        surface: const Color(0xFF171A2A),
        surfaceContainer: const Color(0xFF20243A),
        onSurface: const Color(0xFFF5F6FF),
        outline: const Color(0xFF343955),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color surfaceContainer,
    required Color onSurface,
    required Color outline,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: brightness,
    ).copyWith(
      primary: kPrimary,
      surface: surface,
      surfaceContainerHighest: surfaceContainer,
      onSurface: onSurface,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      primaryColor: kPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF111525)
            : Colors.grey.shade900,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIconColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            brightness == Brightness.dark ? const Color(0xFF262B42) : null,
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appPrimaryBackground =>
      isDarkMode ? const Color(0xFF111525) : kPrimary;

  Color get appPanel => isDarkMode
      ? Theme.of(this).colorScheme.surfaceContainerHighest
      : const Color(0xFFFFF7FF);

  Color get appCard => Theme.of(this).colorScheme.surface;

  Color get appText => Theme.of(this).colorScheme.onSurface;

  Color get appMutedText =>
      isDarkMode ? const Color(0xFFB9BED4) : Colors.black54;

  Color get appSoftFill =>
      isDarkMode ? const Color(0xFF2B3047) : Colors.black.withValues(alpha: 0.05);

  Color get appInputFill => isDarkMode ? const Color(0xFF111525) : Colors.white;

  Color get appTabTrack =>
      isDarkMode ? const Color(0xFF171A2A) : Colors.black.withValues(alpha: 0.06);

  Color get appTabIndicator =>
      isDarkMode ? const Color(0xFF2B3047) : Colors.white;

  Color get appBorder =>
      isDarkMode ? const Color(0xFF383E58) : Colors.black.withValues(alpha: 0.06);

  Color get appShadow =>
      isDarkMode ? Colors.black.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.06);
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeScope.of(context);
    final isDark = controller.isDarkMode;

    return Material(
      color: context.appCard,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: context.isDarkMode ? 0.35 : 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: controller.toggleTheme,
        child: Tooltip(
          message: isDark ? 'Modo claro' : 'Modo oscuro',
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFFFD166) : kPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
