import '../domain/cellular_snapshot.dart';

abstract interface class CellularDataSource {
  Future<CellularSnapshot> readCurrent();

  /// Modem events; Aurora implementation follows emulator API validation.
  Stream<CellularSnapshot> watch();
}
