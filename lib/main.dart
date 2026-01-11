import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:kq/widgets/onBoardingPage.dart';
import 'package:kq/widgets/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_settings_screens
  await Settings.init(cacheProvider: SharePreferenceCache());

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'Kenya Airways',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const OnBoardingPage(),
    );
  }
}
