import '../domain/cellular_snapshot.dart';

abstract interface class CellularDataSource {
  Future<CellularSnapshot> readCurrent();
}
