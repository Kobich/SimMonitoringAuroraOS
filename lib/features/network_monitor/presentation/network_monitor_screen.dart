import 'package:flutter/material.dart';

import '../application/monitoring_dependencies.dart';
import '../data/cellular_data_source.dart';
import '../domain/cellular_snapshot.dart';

class NetworkMonitorScreen extends StatefulWidget {
  const NetworkMonitorScreen({
    super.key,
    required this.dataSource,
    required this.notificationService,
  });

  final CellularDataSource dataSource;
  final NetworkNotificationService notificationService;

  @override
  State<NetworkMonitorScreen> createState() => _NetworkMonitorScreenState();
}

class _NetworkMonitorScreenState extends State<NetworkMonitorScreen> {
  late Future<CellularSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.dataSource.readCurrent();
  }

  Future<void> _refresh() async {
    setState(() => _snapshot = widget.dataSource.readCurrent());
    await _snapshot;
  }

  Future<void> _showTestNotification(CellularSnapshot snapshot) async {
    try {
      await widget.notificationService.showState(snapshot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тестовое уведомление отправлено')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить уведомление: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Мониторинг SIM')),
    body: FutureBuilder<CellularSnapshot>(
      future: _snapshot,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError || !state.hasData) {
          return Center(
            child: Text('Не удалось получить состояние сети: ${state.error}'),
          );
        }
        final snapshot = state.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _OfonoBanner(),
              const SizedBox(height: 16),
              _StatusCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _DetailsCard(snapshot: snapshot),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showTestNotification(snapshot),
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Показать тестовое уведомление'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _OfonoBanner extends StatelessWidget {
  const _OfonoBanner();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'Данные SIM и сети запрашиваются у системного сервиса oFono через D-Bus.',
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});
  final CellularSnapshot snapshot;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _simText(snapshot.simState),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            _radioText(snapshot.radioAccess),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(snapshot.operatorName ?? 'Оператор неизвестен'),
          const SizedBox(height: 8),
          Text(
            snapshot.signalDbm == null
                ? 'Сигнал неизвестен'
                : 'Сигнал: ${snapshot.signalDbm} dBm',
          ),
        ],
      ),
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.snapshot});
  final CellularSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{
      'MCC / MNC': '${snapshot.mcc ?? '—'} / ${snapshot.mnc ?? '—'}',
      'LAC / TAC': snapshot.areaCode ?? '—',
      'Cell ID': snapshot.cellId ?? '—',
      'PCI': snapshot.pci?.toString() ?? '—',
      'Обновлено': TimeOfDay.fromDateTime(snapshot.updatedAt).format(context),
    };
    return Card(
      child: Column(
        children: items.entries
            .map(
              (item) =>
                  ListTile(title: Text(item.key), trailing: Text(item.value)),
            )
            .toList(),
      ),
    );
  }
}

String _simText(SimState state) => switch (state) {
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
