import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fun_timer/screens/settings_screen.dart';
import 'package:fun_timer/utils/storage_helper.dart';
import 'package:fun_timer/utils/notification_helper.dart';
import 'package:fun_timer/utils/background_helper.dart';
import 'package:fun_timer/utils/messages.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isTimerRunning = false;
  String _lastMessage = 'No distraction yet!';
  Timer? _timer;
  Timer? _countdownTimer;
  int _secondsUntilNext = 300; // Default 5 minutes
  late AnimationController _animationController;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _loadBannerAd();
    _checkPermissions();
  }

  void _loadTimerState() async {
    _isTimerRunning = await StorageHelper.getTimerState();
    _secondsUntilNext =
        await StorageHelper.getTimerInterval() * 60; // Load custom interval
    if (_isTimerRunning) {
      _startTimer();
    }
    setState(() {});
  }

  void _checkPermissions() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    if (granted == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable notifications in settings!'),
          ),
        );
      }
    }
  }

  void _startTimer() async {
    int intervalMinutes =
        await StorageHelper.getTimerInterval(); // Get custom interval
    _secondsUntilNext = intervalMinutes * 60;
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) {
      _sendDistraction();
      print('Timer ticked at ${DateTime.now()}');
      setState(() {
        _secondsUntilNext = intervalMinutes * 60; // Reset countdown
      });
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsUntilNext > 0) _secondsUntilNext--;
      });
    });
    BackgroundHelper.registerTask(intervalMinutes);
    StorageHelper.saveTimerState(true);
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    _countdownTimer?.cancel();
    BackgroundHelper.cancelTask();
    StorageHelper.saveTimerState(false);

    _secondsUntilNext = (await StorageHelper.getTimerInterval()) * 60; // Reset
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _sendDistraction() async {
    final randomMessage = await getRandomMessage();
    print('Sending notification: $randomMessage');

    await NotificationHelper.showNotification(
      "Time to Procrastinate 🎉",
      randomMessage,
    );

    setState(() {
      _lastMessage = randomMessage;
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {});
        },
      ),
    )..load();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fun Timer - Procrastinate!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                _loadTimerState(); // Refresh interval if changed
              });
            },
          ),
        ],
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + _animationController.value * 0.1,
                  child: child,
                );
              },
              child: Text(
                _isTimerRunning ? 'Timer Running!' : 'Timer Off',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange, Colors.red]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Text(
                'Next distraction in: ${_formatTime(_secondsUntilNext)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last Distraction: $_lastMessage',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            if (_bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTimerRunning ? _stopTimer : _startTimer,
        tooltip: _isTimerRunning ? 'Stop' : 'Start',
        child: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
