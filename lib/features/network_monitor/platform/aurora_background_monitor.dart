import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/aurora_ofono_cellular_data_source.dart';
import 'aurora_local_notification_service.dart';

const _taskName = 'SimMonitorPeriodic';
const _uniqueTaskName = 'sim-monitor-periodic';

/// Registers an Aurora RuntimeManager periodic task. On Aurora this is launched
/// as a separate service process, independent from the Flutter UI process.
class AuroraBackgroundMonitor {
  static Future<void> initialize() => Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Future<void> startPeriodicMonitoring() async {
    await Workmanager().cancelByUniqueName(_uniqueTaskName);
    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      _taskName,
      frequency: const Duration(minutes: 15),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName) return false;

    try {
      final snapshot = await AuroraOfonoCellularDataSource().readCurrent();
      await AuroraLocalNotificationService().showState(snapshot);
      return true;
    } catch (error) {
      debugPrint('Background SIM monitor task failed: $error');
      return false;
    }
  });
}
