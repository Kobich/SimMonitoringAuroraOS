enum SimState { ready, absent, locked, unknown }

enum RadioAccessType { disconnected, unknown, g2, g3, g4, g5 }

class CellularSnapshot {
  const CellularSnapshot({
    required this.simState,
    required this.radioAccess,
    required this.operatorName,
    required this.signalDbm,
    required this.updatedAt,
    this.mcc,
    this.mnc,
    this.areaCode,
    this.cellId,
    this.pci,
  });

  final SimState simState;
  final RadioAccessType radioAccess;
  final String? operatorName;
  final int? signalDbm;
  final DateTime updatedAt;
  final String? mcc;
  final String? mnc;
  final String? areaCode;
  final String? cellId;
  final int? pci;

  /// Fields whose changes must notify the user. Signal is excluded to avoid spam.
  bool requiresNotificationComparedTo(CellularSnapshot previous) =>
      simState != previous.simState ||
      radioAccess != previous.radioAccess ||
      operatorName != previous.operatorName ||
      mcc != previous.mcc ||
      mnc != previous.mnc;
}
