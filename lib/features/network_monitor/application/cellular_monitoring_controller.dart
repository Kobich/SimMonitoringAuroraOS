import 'dart:async';

import '../data/cellular_data_source.dart';
import '../domain/cellular_snapshot.dart';
import 'monitoring_dependencies.dart';

/// Scenario independent of Flutter UI and a concrete Aurora API.
class CellularMonitoringController {
  CellularMonitoringController({
    required CellularDataSource dataSource,
    required MonitoringSettingsRepository settings,
    required LastSnapshotRepository snapshots,
    required NetworkNotificationService notifications,
  })  : _dataSource = dataSource,
        _settings = settings,
        _snapshots = snapshots,
        _notifications = notifications;

  final CellularDataSource _dataSource;
  final MonitoringSettingsRepository _settings;
  final LastSnapshotRepository _snapshots;
  final NetworkNotificationService _notifications;
  StreamSubscription<CellularSnapshot>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    await _settings.setEnabled(true);
    final initial = await _dataSource.readCurrent();
    await _snapshots.save(initial);
    await _notifications.showState(initial);
    _subscription = _dataSource.watch().listen(_onSnapshot, onError: _onSourceError);
  }

  Future<void> restoreIfEnabled() async {
    if (await _settings.isEnabled()) await start();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _settings.setEnabled(false);
  }

  Future<void> _onSnapshot(CellularSnapshot current) async {
    final previous = await _snapshots.read();
    if (previous == null || current.requiresNotificationComparedTo(previous)) {
      await _notifications.showState(current);
    }
    await _snapshots.save(current);
  }

  void _onSourceError(Object error, StackTrace stackTrace) {}
}
