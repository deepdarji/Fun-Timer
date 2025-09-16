import 'package:flutter/material.dart';
import 'package:fun_timer/screens/home_screen.dart';
import 'package:fun_timer/utils/notification_helper.dart';
import 'package:fun_timer/utils/background_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // Init ads
  await NotificationHelper.init(); // Init notifications
  await BackgroundHelper.init(); // Init background tasks
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fun Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        scaffoldBackgroundColor: Colors.orange[50],
      ),
      home: const HomeScreen(),
    );
  }
}
