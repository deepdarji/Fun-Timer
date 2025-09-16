import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fun_timer/screens/settings_screen.dart';
import 'package:fun_timer/utils/storage_helper.dart';
import 'package:fun_timer/utils/notification_helper.dart';
import 'package:fun_timer/utils/background_helper.dart';
import 'package:fun_timer/utils/messages.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wheel_chooser/wheel_chooser.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added for plugin access

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
  int _secondsUntilNext = 300; // Default 5 min in seconds
  int _timerInterval = 5; // Default interval in minutes
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
    _timerInterval = await StorageHelper.getTimerInterval();
    _secondsUntilNext = _timerInterval * 60;
    if (_isTimerRunning) {
      _startTimer();
    }
    setState(() {});
  }

  void _checkPermissions() async {
    bool? androidGranted = await NotificationHelper.notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (androidGranted == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable notifications in settings!'),
        ),
      );
    }
  }

  void _startTimer() {
    // Cancel existing timers to prevent glitches
    _timer?.cancel();
    _countdownTimer?.cancel();

    _timer = Timer.periodic(Duration(minutes: _timerInterval), (timer) {
      _sendDistraction();
      print('Timer ticked at ${DateTime.now()}');
      setState(() {
        _secondsUntilNext = _timerInterval * 60; // Reset countdown
      });
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsUntilNext > 0) {
        setState(() {
          _secondsUntilNext--;
        });
      } else {
        _secondsUntilNext = _timerInterval * 60; // Reset if out of sync
      }
    });
    BackgroundHelper.registerTask(_timerInterval);
    StorageHelper.saveTimerState(true);
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    BackgroundHelper.cancelTask();
    StorageHelper.saveTimerState(false);
    setState(() {
      _isTimerRunning = false;
      _secondsUntilNext = _timerInterval * 60;
    });
  }

  void _sendDistraction() async {
    final randomMessage = await getRandomMessage();
    print('Sending notification: $randomMessage');
    await NotificationHelper.showNotification(
      'Distraction Time!',
      randomMessage,
    );
    setState(() {
      _lastMessage = randomMessage;
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7253685603699909/7350098010', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed: $error');
        },
      ),
    )..load();
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  void _showIntervalPicker() {
    int selectedInterval = _timerInterval;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.orange[100],
          title: const Text(
            'Set Timer Interval (minutes)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            height: 200,
            width: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.red],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: WheelChooser.integer(
              onValueChanged: (value) {
                selectedInterval = value;
              },
              minValue: 1,
              maxValue: 30,
              initValue: _timerInterval,
              itemSize: 50,
              magnification: 1.5,
              step: 1,
              horizontal: false,
              unSelectTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
              selectTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (selectedInterval != _timerInterval) {
                  _timerInterval = selectedInterval;
                  await StorageHelper.saveTimerInterval(selectedInterval);
                  _secondsUntilNext = selectedInterval * 60;
                  if (_isTimerRunning) {
                    _stopTimer();
                    _startTimer();
                  }
                }
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Set', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
            icon: const Icon(Icons.timer),
            onPressed: _showIntervalPicker,
            tooltip: 'Set Interval',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Text(
                'Next Distraction in: ${_formatTime(_secondsUntilNext)}',
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
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                ),
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
