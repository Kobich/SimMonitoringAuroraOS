import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_monitor/data/mock_cellular_data_source.dart';
import 'package:network_monitor/main.dart';

void main() {
  testWidgets('shows SIM monitor screen', (tester) async {
    await tester.pumpWidget(
      SimMonitorApp(dataSource: MockCellularDataSource()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Мониторинг SIM'), findsOneWidget);
    expect(find.text('SIM готова'), findsOneWidget);
    expect(find.text('4G / LTE'), findsOneWidget);
    expect(find.text('Показать тестовое уведомление'), findsOneWidget);
  });
}
