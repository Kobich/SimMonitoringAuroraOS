import '../domain/cellular_snapshot.dart';

abstract interface class MonitoringSettingsRepository {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool value);
}

abstract interface class LastSnapshotRepository {
  Future<CellularSnapshot?> read();
  Future<void> save(CellularSnapshot snapshot);
}

abstract interface class NetworkNotificationService {
  Future<void> showState(CellularSnapshot snapshot);
}
