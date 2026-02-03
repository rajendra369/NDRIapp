import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/data_record.dart';
import '../bloc/records_bloc.dart';
import '../bloc/records_state.dart';
import '../../../settings/data/datasources/csv_export_service.dart';
import '../../data/datasources/firestore_service.dart';
import '../widgets/record_card.dart';

class ViewDataScreen extends StatefulWidget {
  const ViewDataScreen({super.key});

  @override
  State<ViewDataScreen> createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends State<ViewDataScreen> {
  final CsvExportService _csvExportService = CsvExportService();

  // Filters
  DateTimeRange? _dateRange;
  String? _selectedStation;

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

  Future<void> _exportRainData() async {
    try {
      final allRecords = await FirestoreService().getAllRecords();
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

  Future<void> _exportDischargeData() async {
    try {
      final allRecords = await FirestoreService().getAllRecords();
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
      if (_dateRange != null) {
        final recordDate = DateTime.parse(record.date);
        if (recordDate.isBefore(_dateRange!.start) ||
            recordDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      if (_selectedStation != null && _selectedStation!.isNotEmpty) {
        final stationMatches =
            (record.rainStation == _selectedStation) ||
            (record.flowStation == _selectedStation);
        if (!stationMatches) return false;
      }

      return true;
    }).toList();
  }

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
                          _exportRainData();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.waves),
                        title: const Text('Export Spring Discharge Data'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportDischargeData();
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
      body: BlocBuilder<RecordsBloc, RecordsState>(
        builder: (context, state) {
          if (state is RecordsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is RecordsLoading || state is RecordsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RecordsLoaded) {
            final allRecords = state.records;
            final filteredRecords = _filterRecords(allRecords);
            final uniqueStations = _getUniqueStations(allRecords);

            return Column(
              children: [
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
                          value: _selectedStation,
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
          }
          return const SizedBox();
        },
      ),
    );
  }
}
