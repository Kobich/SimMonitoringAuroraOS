import 'dart:convert';
import 'dart:io';

import '../application/monitoring_dependencies.dart';
import '../domain/cellular_snapshot.dart';

/// Persists the monitoring flag and the last real oFono snapshot.
///
/// Aurora Workmanager starts a separate process, so in-memory state is not
/// shared with the UI process. The state therefore lives in the application's
/// XDG data directory, which is allowed by the UserDirs permission.
class AuroraFileMonitoringStateStore
    implements MonitoringSettingsRepository, LastSnapshotRepository {
  static const _fileName = 'monitoring_state.json';

  @override
  Future<bool> isEnabled() async => (await _readState())['enabled'] == true;

  @override
  Future<void> setEnabled(bool value) async {
    final state = await _readState();
    state['enabled'] = value;
    await _writeState(state);
  }

  @override
  Future<CellularSnapshot?> read() async {
    final json = (await _readState())['snapshot'];
    if (json is! Map) return null;

    try {
      return _snapshotFromJson(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(CellularSnapshot snapshot) async {
    final state = await _readState();
    state['snapshot'] = _snapshotToJson(snapshot);
    await _writeState(state);
  }

  Future<Map<String, dynamic>> _readState() async {
    final file = await _stateFile();
    if (!await file.exists()) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } on FileSystemException {
      return <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeState(Map<String, dynamic> state) async {
    final file = await _stateFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state), flush: true);
  }

  Future<File> _stateFile() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('HOME is unavailable in Aurora application sandbox');
    }
    final dataHome =
        Platform.environment['XDG_DATA_HOME'] ?? '$home/.local/share';
    return File('$dataHome/ru.networkmonitor.network_monitor/$_fileName');
  }

  Map<String, dynamic> _snapshotToJson(CellularSnapshot snapshot) => {
    'simState': snapshot.simState.name,
    'radioAccess': snapshot.radioAccess.name,
    'operatorName': snapshot.operatorName,
    'signalDbm': snapshot.signalDbm,
    'updatedAt': snapshot.updatedAt.toUtc().toIso8601String(),
    'mcc': snapshot.mcc,
    'mnc': snapshot.mnc,
    'areaCode': snapshot.areaCode,
    'cellId': snapshot.cellId,
    'pci': snapshot.pci,
  };

  CellularSnapshot _snapshotFromJson(Map<String, dynamic> json) =>
      CellularSnapshot(
        simState: SimState.values.firstWhere(
          (state) => state.name == json['simState'],
          orElse: () => SimState.unknown,
        ),
        radioAccess: RadioAccessType.values.firstWhere(
          (type) => type.name == json['radioAccess'],
          orElse: () => RadioAccessType.unknown,
        ),
        operatorName: _string(json['operatorName']),
        signalDbm: _int(json['signalDbm']),
        updatedAt:
            DateTime.tryParse(_string(json['updatedAt']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        mcc: _string(json['mcc']),
        mnc: _string(json['mnc']),
        areaCode: _string(json['areaCode']),
        cellId: _string(json['cellId']),
        pci: _int(json['pci']),
      );

  String? _string(Object? value) => value is String ? value : null;

  int? _int(Object? value) => value is int ? value : null;
}
