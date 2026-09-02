import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'features/network_monitor/application/cellular_monitoring_controller.dart';
import 'features/network_monitor/data/aurora_file_monitoring_state_store.dart';
import 'features/network_monitor/data/aurora_ofono_cellular_data_source.dart';
import 'features/network_monitor/data/cellular_data_source.dart';
import 'features/network_monitor/platform/aurora_local_notification_service.dart';
import 'features/network_monitor/presentation/network_monitor_screen.dart';

const _periodicTaskName = 'SimMonitorPeriodic';
const _periodicTaskUniqueName =
    'ru.networkmonitor.network_monitor.periodic-monitor';

/// Entry point started by Aurora Workmanager in a separate Dart isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != _periodicTaskName) return false;

    try {
      final stateStore = AuroraFileMonitoringStateStore();
      final controller = CellularMonitoringController(
        dataSource: AuroraOfonoCellularDataSource(),
        settings: stateStore,
        snapshots: stateStore,
        notifications: AuroraLocalNotificationService(),
      );
      await controller.checkOnce();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Background SIM monitor failed: $error\n$stackTrace');
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _enablePeriodicMonitoring();
  runApp(const SimMonitorApp());
}

Future<void> _enablePeriodicMonitoring() async {
  try {
    final stateStore = AuroraFileMonitoringStateStore();
    await stateStore.setEnabled(true);

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      _periodicTaskUniqueName,
      _periodicTaskName,
      frequency: const Duration(minutes: 15),
    );
  } catch (error, stackTrace) {
    debugPrint('Unable to configure Aurora Workmanager: $error\n$stackTrace');
  }
}

class SimMonitorApp extends StatelessWidget {
  const SimMonitorApp({super.key, this.dataSource});

  final CellularDataSource? dataSource;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SIM Monitor',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    ),
    home: NetworkMonitorScreen(
      dataSource: dataSource ?? AuroraOfonoCellularDataSource(),
      notificationService: AuroraLocalNotificationService(),
    ),
  );
}
