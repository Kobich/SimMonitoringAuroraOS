import 'package:dbus/dbus.dart';

/// Registers the periodic monitor task declared in the Aurora desktop file.
///
/// RuntimeManager itself owns the schedule and launches a separate process.
/// This class deliberately speaks to the public session D-Bus API, so the
/// Flutter PSDK does not need RuntimeManager C++ headers or libraries.
class AuroraRuntimeManagerTaskScheduler {
  static const _serviceName = 'ru.omp.RuntimeManager';
  static const _objectPath = '/ru/omp/RuntimeManager/Tasks1';
  static const _interfaceName = 'ru.omp.RuntimeManager.Tasks1';

  // OrganizationName + ApplicationName + task name from the .desktop file.
  static const _fullTaskId =
      'ru.networkmonitor.network_monitor.SimMonitorPeriodic';

  // Requested cadence. RuntimeManager may apply platform-level throttling.
  static const _intervalSeconds = 5 * 60;
  static const _maximumRunningTimeSeconds = 60;

  Future<void> ensurePeriodicMonitorScheduled() async {
    final client = DBusClient.session();

    try {
      final tasks = DBusRemoteObject(
        client,
        name: _serviceName,
        path: DBusObjectPath(_objectPath),
      );

      await tasks.callMethod(_interfaceName, 'Start', [
        const DBusString(_fullTaskId),
        DBusArray.string(const []),
        DBusDict.stringVariant({
          'interval': DBusInt32(_intervalSeconds),
          'maximumRunningTime': DBusInt32(_maximumRunningTimeSeconds),
          'autostart': const DBusBoolean(true),
        }),
      ]);
    } finally {
      await client.close();
    }
  }
}
