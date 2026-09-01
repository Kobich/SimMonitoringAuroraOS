import 'package:flutter/material.dart';

import 'features/network_monitor/data/aurora_ofono_cellular_data_source.dart';
import 'features/network_monitor/data/cellular_data_source.dart';
import 'features/network_monitor/platform/aurora_local_notification_service.dart';
import 'features/network_monitor/presentation/network_monitor_screen.dart';

void main() {
  runApp(const SimMonitorApp());
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
