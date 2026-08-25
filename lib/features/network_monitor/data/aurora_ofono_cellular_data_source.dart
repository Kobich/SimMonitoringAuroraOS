import 'package:dbus/dbus.dart';

import 'cellular_data_source.dart';
import '../domain/cellular_snapshot.dart';

/// Reads the current modem state from the public oFono D-Bus service.
class AuroraOfonoCellularDataSource implements CellularDataSource {
  AuroraOfonoCellularDataSource({
    Duration pollInterval = const Duration(seconds: 15),
  }) : _pollInterval = pollInterval;

  final Duration _pollInterval;

  @override
  Future<CellularSnapshot> readCurrent() async {
    final client = DBusClient.system();
    try {
      final modem = await _findModem(client);
      final sim = await _getProperties(modem, 'org.ofono.SimManager');
      final network = await _getProperties(
        modem,
        'org.ofono.NetworkRegistration',
      );

      final simState = _simState(sim);
      final status = _string(network['Status']);
      final technology = _string(network['Technology']);

      return CellularSnapshot(
        simState: simState,
        radioAccess: _radioAccess(status, technology),
        operatorName: _string(network['Name']),
        // oFono exposes Strength in percent, not dBm. Do not invent dBm.
        signalDbm: null,
        mcc: _string(network['MobileCountryCode']),
        mnc: _string(network['MobileNetworkCode']),
        areaCode: _string(network['LocationAreaCode']),
        cellId: _string(network['CellId']),
        pci: null,
        updatedAt: DateTime.now(),
      );
    } finally {
      await client.close();
    }
  }

  @override
  Stream<CellularSnapshot> watch() async* {
    yield await readCurrent();
    yield* Stream.periodic(_pollInterval).asyncMap((_) => readCurrent());
  }

  Future<DBusRemoteObject> _findModem(DBusClient client) async {
    final manager = DBusRemoteObject(
      client,
      name: 'org.ofono',
      path: DBusObjectPath('/'),
    );
    final response = await manager.callMethod('org.ofono.Manager', 'GetModems', []);
    final modems = response.returnValues.single.asArray();
    if (modems.isEmpty) {
      throw StateError('oFono не сообщает доступных модемов');
    }
    final modem = modems.first.asStruct();
    return DBusRemoteObject(
      client,
      name: 'org.ofono',
      path: modem.first.asObjectPath(),
    );
  }

  Future<Map<String, DBusValue>> _getProperties(
    DBusRemoteObject modem,
    String interfaceName,
  ) async {
    final response = await modem.callMethod(interfaceName, 'GetProperties', []);
    return response.returnValues.single.asStringVariantDict();
  }

  SimState _simState(Map<String, DBusValue> properties) {
    if (_bool(properties['Present']) == false) return SimState.absent;
    final pinRequired = _string(properties['PinRequired']);
    if (pinRequired != null && pinRequired != 'none') return SimState.locked;
    return _bool(properties['Present']) == true
        ? SimState.ready
        : SimState.unknown;
  }

  RadioAccessType _radioAccess(String? status, String? technology) {
    const notRegistered = {'unregistered', 'denied', 'searching', 'unknown'};
    if (status == null || notRegistered.contains(status)) {
      return RadioAccessType.disconnected;
    }
    return switch (technology?.toLowerCase()) {
      'gsm' || 'gprs' || 'edge' => RadioAccessType.g2,
      'umts' || 'hsdpa' || 'hsupa' || 'hspa' || 'hspa+' => RadioAccessType.g3,
      'lte' || 'lte_ca' => RadioAccessType.g4,
      'nr' || '5g' || 'nr5g' => RadioAccessType.g5,
      _ => RadioAccessType.unknown,
    };
  }

  String? _string(DBusValue? value) {
    final native = value?.toNative();
    return native is String ? native : native?.toString();
  }

  bool? _bool(DBusValue? value) {
    final native = value?.toNative();
    return native is bool ? native : null;
  }
}
