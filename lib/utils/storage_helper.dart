import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<bool> getTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('timer_running') ?? false;
  }

  static Future<void> saveTimerState(bool isRunning) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('timer_running', isRunning);
  }

  static Future<List<String>> getCustomMessages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('custom_messages') ?? [];
  }

  static Future<void> saveCustomMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('custom_messages', messages);
  }

  static Future<int> getTimerInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('timer_interval') ?? 5; // Default 5 minutes
  }

  static Future<void> saveTimerInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('timer_interval', interval);
  }
}
