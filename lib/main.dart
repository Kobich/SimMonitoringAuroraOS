import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'features/network_monitor/data/aurora_ofono_cellular_data_source.dart';
import 'features/network_monitor/data/cellular_data_source.dart';
import 'features/network_monitor/platform/aurora_local_notification_service.dart';
import 'features/network_monitor/platform/aurora_runtime_manager_task_scheduler.dart';
import 'features/network_monitor/presentation/network_monitor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_scheduleBackgroundMonitor());
  runApp(const SimMonitorApp());
}

Future<void> _scheduleBackgroundMonitor() async {
  try {
    await AuroraRuntimeManagerTaskScheduler().ensurePeriodicMonitorScheduled();
  } catch (error, stackTrace) {
    debugPrint(
      'Unable to schedule Aurora background monitor: $error\n$stackTrace',
    );
  }
}

/// RuntimeManager starts this top-level entry point in a process without UI.
///
/// It intentionally performs exactly one short monitoring pass. Aurora owns
/// scheduling and may stop/recreate the process between periodic ticks.
@pragma('vm:entry-point')
Future<void> backgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final snapshot = await AuroraOfonoCellularDataSource().readCurrent();
    await AuroraLocalNotificationService().showState(snapshot);
    exit(0);
  } catch (error, stackTrace) {
    debugPrint('Background SIM monitor task failed: $error\n$stackTrace');
    exit(1);
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
