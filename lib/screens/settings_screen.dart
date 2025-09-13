import 'package:flutter/material.dart';
import 'package:fun_timer/utils/storage_helper.dart';
import 'package:fun_timer/utils/messages.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  List<String> _customMessages = [];
  int _timerInterval = 5; // Default 5 minutes
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadCustomMessages();
    _loadTimerInterval();
    _loadInterstitialAd();
  }

  void _loadCustomMessages() async {
    _customMessages = await StorageHelper.getCustomMessages();
    setState(() {});
  }

  void _loadTimerInterval() async {
    _timerInterval = await StorageHelper.getTimerInterval();
    _intervalController.text = _timerInterval.toString();
    setState(() {});
  }

  void _addMessage() {
    if (_controller.text.isNotEmpty) {
      _customMessages.add(_controller.text);
      StorageHelper.saveCustomMessages(_customMessages);
      _controller.clear();
      setState(() {});
      _showAd();
    }
  }

  void _saveTimerInterval() {
    int? newInterval = int.tryParse(_intervalController.text);
    if (newInterval != null && newInterval >= 1 && newInterval <= 30) {
      _timerInterval = newInterval;
      StorageHelper.saveTimerInterval(newInterval);
      setState(() {});
      _showAd();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a number between 1 and 30 minutes')),
      );
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  void _showAd() {
    _interstitialAd?.show();
    _interstitialAd = null;
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _intervalController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Add Custom Excuse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Add Excuse'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(
                labelText: 'Timer Interval (minutes, 1-30)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveTimerInterval,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Set Interval'),
            ),
            const SizedBox(height: 20),
            const Text('Your Custom Excuses:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: _customMessages.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(title: Text(_customMessages[index])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
