import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../application/monitoring_dependencies.dart';
import '../domain/cellular_snapshot.dart';

class AuroraLocalNotificationService implements NetworkNotificationService {
  AuroraLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _nextId = 1;

  @override
  Future<void> showState(CellularSnapshot snapshot) => _plugin.show(
    id: _nextId++,
    title: 'SIM Monitor: ${_simStateText(snapshot.simState)}',
    body: '${_radioText(snapshot.radioAccess)} · '
        '${snapshot.operatorName ?? 'Оператор неизвестен'}',
    payload: null,
  );

  String _simStateText(SimState state) => switch (state) {
    SimState.ready => 'SIM готова',
    SimState.absent => 'SIM отсутствует',
    SimState.locked => 'SIM заблокирована',
    SimState.unknown => 'Состояние SIM неизвестно',
  };

  String _radioText(RadioAccessType type) => switch (type) {
    RadioAccessType.disconnected => 'Мобильная сеть отключена',
    RadioAccessType.unknown => 'Тип сети неизвестен',
    RadioAccessType.g2 => '2G',
    RadioAccessType.g3 => '3G',
    RadioAccessType.g4 => '4G / LTE',
    RadioAccessType.g5 => '5G',
  };
}
