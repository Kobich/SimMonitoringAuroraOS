import '../domain/cellular_snapshot.dart';
import 'cellular_data_source.dart';

class MockCellularDataSource implements CellularDataSource {
  @override
  Future<CellularSnapshot> readCurrent() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return CellularSnapshot(
      simState: SimState.ready,
      radioAccess: RadioAccessType.g4,
      operatorName: 'Mock Telecom',
      signalDbm: -87,
      mcc: '250',
      mnc: '99',
      areaCode: '12345',
      cellId: '67890123',
      pci: 167,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<CellularSnapshot> watch() => const Stream.empty();
}
