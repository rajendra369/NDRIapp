import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/collector.dart';
import '../../../dashboard/presentation/bloc/collectors_bloc.dart';
import '../../../dashboard/presentation/bloc/collectors_event.dart';
import '../../../dashboard/presentation/bloc/collectors_state.dart';
import '../../../dashboard/presentation/bloc/records_bloc.dart';
import '../../../dashboard/presentation/bloc/records_event.dart';
import '../../../dashboard/presentation/bloc/records_state.dart';
import 'import_data_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _collectorController = TextEditingController();

  @override
  void dispose() {
    _collectorController.dispose();
    super.dispose();
  }

  Future<void> _addCollectorDialog(BuildContext context) async {
    _collectorController.clear();
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Data Collector'),
        content: TextField(
          controller: _collectorController,
          decoration: const InputDecoration(hintText: 'Enter name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_collectorController.text.isNotEmpty) {
                context.read<CollectorsBloc>().add(
                  CollectorAdded(_collectorController.text.trim()),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editStations(BuildContext context, Collector collector) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _StationEditor(collector: collector),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CollectorsBloc, CollectorsState>(
          listener: (context, state) {
            if (state is CollectorsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is CollectorOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Operation successful')),
              );
            }
          },
        ),
        BlocListener<RecordsBloc, RecordsState>(
          listener: (context, state) {
            if (state is RecordsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addCollectorDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Collector'),
        ),
        body: BlocBuilder<CollectorsBloc, CollectorsState>(
          builder: (context, state) {
            if (state is CollectorsLoading || state is CollectorsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CollectorsLoaded ||
                state is CollectorOperationSuccess) {
              final collectors = state is CollectorsLoaded
                  ? state.collectors
                  : (context.read<CollectorsBloc>().state as CollectorsLoaded)
                        .collectors;

              if (collectors.isEmpty) {
                return const Center(
                  child: Text('No collectors found. Add one!'),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: collectors.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final collector = collectors[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(collector.name[0].toUpperCase()),
                            ),
                            title: Text(collector.name),
                            subtitle: Text(
                              '${collector.rainStations.length} Rain • ${collector.flowStations.length} Flow',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _editStations(context, collector),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Manage Stations'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(context, collector),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImportDataScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_upload),
                        label: const Text('Import Historical Data (Excel)'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue[800],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmResetData(context),
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'RESET ALL ENTERED DATA',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> _confirmResetData(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all recorded Rainfall and Discharge entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<RecordsBloc>().add(RecordsClearRequested());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Clearing data...')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET EVERYTHING'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Collector collector) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Collector?'),
        content: Text('Are you sure you want to remove "${collector.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CollectorsBloc>().add(
                CollectorRemoved(collector.id),
              );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StationEditor extends StatefulWidget {
  final Collector collector;

  const _StationEditor({required this.collector});

  @override
  State<_StationEditor> createState() => _StationEditorState();
}

class _StationEditorState extends State<_StationEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Collector _currentCollector;
  final TextEditingController _stationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentCollector = widget.collector;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  void _addStation(bool isRain) {
    if (_stationController.text.isEmpty) return;

    final newStation = _stationController.text.trim();
    final updatedCollector = _currentCollector.copyWith(
      rainStations: isRain
          ? [..._currentCollector.rainStations, newStation]
          : null,
      flowStations: !isRain
          ? [..._currentCollector.flowStations, newStation]
          : null,
    );

    setState(() => _currentCollector = updatedCollector);
    _stationController.clear();
    context.read<CollectorsBloc>().add(CollectorUpdated(updatedCollector));
  }

  void _removeStation(String station, bool isRain) {
    final updatedCollector = _currentCollector.copyWith(
      rainStations: isRain
          ? _currentCollector.rainStations.where((s) => s != station).toList()
          : null,
      flowStations: !isRain
          ? _currentCollector.flowStations.where((s) => s != station).toList()
          : null,
    );

    setState(() => _currentCollector = updatedCollector);
    context.read<CollectorsBloc>().add(CollectorUpdated(updatedCollector));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_currentCollector.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rain Stations'),
            Tab(text: 'Flow Stations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildList(true), _buildList(false)],
      ),
    );
  }

  Widget _buildList(bool isRain) {
    final stations = isRain
        ? _currentCollector.rainStations
        : _currentCollector.flowStations;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stationController,
                  decoration: const InputDecoration(
                    labelText: 'Add New Station ID',
                    prefixIcon: Icon(Icons.add_location_alt),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addStation(isRain),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: stations.isEmpty
              ? const Center(child: Text('No stations assigned'))
              : ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return ListTile(
                      title: Text(station),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeStation(station, isRain),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
