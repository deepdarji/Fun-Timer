import 'package:flutter/material.dart';
import 'package:fun_timer/utils/storage_helper.dart';
import 'package:fun_timer/utils/messages.dart'; // To add excuses
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For interstitial ad

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _customMessages = [];
  InterstitialAd? _interstitialAd; // Ad on settings

  @override
  void initState() {
    super.initState();
    _loadCustomMessages();
    _loadInterstitialAd(); // Load ad
  }

  // Load saved custom messages
  void _loadCustomMessages() async {
    _customMessages = await StorageHelper.getCustomMessages();
    setState(() {});
  }

  // Add new message
  void _addMessage() {
    if (_controller.text.isNotEmpty) {
      _customMessages.add(_controller.text);
      StorageHelper.saveCustomMessages(_customMessages);
      _controller.clear();
      setState(() {});
      _showAd(); // Show ad after adding
    }
  }

  // Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7253685603699909/6312348511', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  // Show ad if loaded
  void _showAd() {
    _interstitialAd?.show();
    _interstitialAd = null; // Reload after show
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _controller.dispose();
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
                  borderRadius: BorderRadius.circular(20), // Cool rounded
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
              child: const Text('Add'),
            ),
            const SizedBox(height: 20),
            const Text('Your Custom Excuses:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: _customMessages.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4, // Shadow for cool look
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
