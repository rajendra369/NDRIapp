import 'package:flutter/material.dart';
import '../models/collector.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _collectorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-seed on first load if empty
    _firestoreService.seedDefaultCollectors();
  }

  @override
  void dispose() {
    _collectorController.dispose();
    super.dispose();
  }

  Future<void> _addCollectorDialog() async {
    _collectorController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Data Collector'),
        content: TextField(
          controller: _collectorController,
          decoration: const InputDecoration(hintText: 'Enter name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_collectorController.text.isNotEmpty) {
                await _firestoreService.addCollector(
                  _collectorController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editStations(Collector collector) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _StationEditor(
        collector: collector,
        firestoreService: _firestoreService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCollectorDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Collector'),
      ),
      body: StreamBuilder<List<Collector>>(
        stream: _firestoreService.getCollectorsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final collectors = snapshot.data!;

          if (collectors.isEmpty) {
            return const Center(child: Text('No collectors found. Add one!'));
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
                                  onPressed: () => _editStations(collector),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Manage Stations'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(collector),
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
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmResetData,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
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
        },
      ),
    );
  }

  Future<void> _confirmResetData() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all recorded Rainfall and Discharge entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.clearAllRecords();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset.')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET EVERYTHING'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Collector collector) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collector?'),
        content: Text('Are you sure you want to remove "${collector.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.removeCollector(collector.id);
              if (context.mounted) Navigator.pop(context);
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
  final FirestoreService firestoreService;

  const _StationEditor({
    required this.collector,
    required this.firestoreService,
  });

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

  Future<void> _addStation(bool isRain) async {
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

    // Optimistic update
    setState(() => _currentCollector = updatedCollector);
    _stationController.clear();

    try {
      await widget.firestoreService.updateCollector(updatedCollector);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeStation(String station, bool isRain) async {
    final updatedCollector = _currentCollector.copyWith(
      rainStations: isRain
          ? _currentCollector.rainStations.where((s) => s != station).toList()
          : null,
      flowStations: !isRain
          ? _currentCollector.flowStations.where((s) => s != station).toList()
          : null,
    );

    setState(() => _currentCollector = updatedCollector);

    try {
      await widget.firestoreService.updateCollector(updatedCollector);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
