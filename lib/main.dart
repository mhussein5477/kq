import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:kq/widgets/onBoardingPage.dart';
import 'package:kq/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_settings_screens
  await Settings.init(cacheProvider: SharePreferenceCache());
  
  // Initialize theme service
  await ThemeService.init();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    ThemeService.themeNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService.themeNotifier.value == ThemeMode.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
    );

    return MaterialApp(
      title: 'Kenya Airways',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeService.themeNotifier.value,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFE31E24),
        scaffoldBackgroundColor: const Color(0xFFF5F5F8),
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFE31E24),
          secondary: const Color(0xFFE31E24),
          surface: Colors.white,
          background: const Color(0xFFF5F5F8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFFE31E24),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE31E24),
          secondary: const Color(0xFFE31E24),
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const OnBoardingPage(),
    );
  }
}