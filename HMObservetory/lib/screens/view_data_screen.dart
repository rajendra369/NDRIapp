import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/data_record.dart';
import '../services/firestore_service.dart';
import '../services/csv_export_service.dart';
import '../widgets/record_card.dart';

class ViewDataScreen extends StatefulWidget {
  const ViewDataScreen({super.key});

  @override
  State<ViewDataScreen> createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends State<ViewDataScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CsvExportService _csvExportService = CsvExportService();

  // Filters
  DateTimeRange? _dateRange;
  String? _selectedStation; // Can be rain or flow station name

  // Computed properties

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _exportRainData(List<DataRecord> records) async {
    try {
      // Export only filtered records? Or all? Usually users expect to export what they see,
      // but the original requirement might be all. Let's export ALL for consistency with original app,
      // or we can filter. Let's keep it simple: Export ALL for now, or filtered if preferred.
      // Reverting to ALL as per original code, but maybe filtered is better?
      // Let's stick to ALL to be safe, or ALL-FILTERED.
      // Implementation: Export ALL from DB to avoid confusion.
      final allRecords = await _firestoreService.getAllRecords();
      await _csvExportService.exportRainData(allRecords);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rainfall data exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportDischargeData(List<DataRecord> records) async {
    try {
      final allRecords = await _firestoreService.getAllRecords();
      await _csvExportService.exportDischargeData(allRecords);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discharge data exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<DataRecord> _filterRecords(List<DataRecord> records) {
    return records.where((record) {
      // 1. Date Filter
      if (_dateRange != null) {
        final recordDate = DateTime.parse(record.date);
        if (recordDate.isBefore(_dateRange!.start) ||
            recordDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // 2. Station Filter
      if (_selectedStation != null && _selectedStation!.isNotEmpty) {
        final stationMatches =
            (record.rainStation == _selectedStation) ||
            (record.flowStation == _selectedStation);
        if (!stationMatches) return false;
      }

      return true;
    }).toList();
  }

  // Get unique stations from records for the filter dropdown
  List<String> _getUniqueStations(List<DataRecord> records) {
    final Set<String> stations = {};
    for (var r in records) {
      if (r.rainStation != null) stations.add(r.rainStation!);
      if (r.flowStation != null) stations.add(r.flowStation!);
    }
    return stations.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: () {
              // Show bottom sheet for export options
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.water_drop),
                        title: const Text('Export Rainfall Data'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportRainData([]);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.waves),
                        title: const Text('Export Spring Discharge Data'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportDischargeData([]);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DataRecord>>(
        stream: _firestoreService.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snapshot.data!;
          final filteredRecords = _filterRecords(allRecords);
          final uniqueStations = _getUniqueStations(allRecords);

          // Defer updating count to avoid build conflicts if needed, but here it's fine
          // _recordCount = filteredRecords.length;

          return Column(
            children: [
              // Filters Section
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                _dateRange == null
                                    ? 'All Dates'
                                    : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                              ),
                            ),
                          ),
                          if (_dateRange != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _dateRange = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStation,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Station',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Stations'),
                          ),
                          ...uniqueStations.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedStation = val),
                      ),
                    ],
                  ),
                ),
              ),

              // Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing ${filteredRecords.length} records',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),

              // List
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(
                        child: Text('No records found matching filters.'),
                      )
                    : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          return RecordCard(record: filteredRecords[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
