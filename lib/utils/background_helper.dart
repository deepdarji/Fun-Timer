import 'package:workmanager/workmanager.dart';
import 'package:fun_timer/utils/notification_helper.dart';
import 'package:fun_timer/utils/messages.dart';

const String taskName = 'distraction_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background task running at ${DateTime.now()}');
    final message = await getRandomMessage();
    await NotificationHelper.showNotification(
      'Background Distraction!',
      message,
    );
    return Future.value(true);
  });
}

class BackgroundHelper {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static void registerTask(int intervalMinutes) {
    Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(minutes: intervalMinutes),
    );
  }

  static void cancelTask() {
    Workmanager().cancelByUniqueName(taskName);
  }
}
