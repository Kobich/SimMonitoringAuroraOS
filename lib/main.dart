import 'package:flutter/material.dart';

import 'features/network_monitor/data/mock_cellular_data_source.dart';
import 'features/network_monitor/platform/aurora_local_notification_service.dart';
import 'features/network_monitor/presentation/network_monitor_screen.dart';

void main() {
  runApp(const SimMonitorApp());
}

class SimMonitorApp extends StatelessWidget {
  const SimMonitorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SIM Monitor',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    ),
    home: NetworkMonitorScreen(
      dataSource: MockCellularDataSource(),
      notificationService: AuroraLocalNotificationService(),
    ),
  );
}
