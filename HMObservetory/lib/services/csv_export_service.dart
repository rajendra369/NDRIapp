import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data_record.dart';
import '../models/station_mapping.dart';

class CsvExportService {
  // Export rainfall data in wide format
  Future<void> exportRainData(List<DataRecord> records) async {
    final stations = StationMapping.getAllRainStations();

    if (stations.isEmpty) {
      throw Exception('No rainfall stations found');
    }

    // Build CSV content
    final List<List<dynamic>> rows = [];

    // --- HEADER GENERATION (8 Rows from V1) ---
    final List<String> regions = ['District'];
    final List<String> munis = ['Municipality/Ward'];
    final List<String> locs = ['Location Description'];
    final List<String> lats = ['Latitude (*N)'];
    final List<String> lons = ['Longitude (*E)'];
    final List<String> alts = ['Altitude (m)'];
    final List<String> collectors = ['Data collector (Name & Contact)'];
    final List<String> dateHeader = ['Date A.D.'];

    for (var st in stations) {
      final meta = StationMapping.metadata[st] ?? {};
      regions.add(meta['region'] ?? '');
      munis.add(meta['muni'] ?? '');
      locs.add(meta['loc'] ?? '');
      lats.add(meta['lat'] ?? '');
      lons.add(meta['lon'] ?? '');
      alts.add(meta['alt'] ?? '');
      collectors.add(meta['collector'] ?? '');
      dateHeader.add(st); // Station ID in the 8th header row
    }

    rows.add(regions);
    rows.add(munis);
    rows.add(locs);
    rows.add(lats);
    rows.add(lons);
    rows.add(alts);
    rows.add(collectors);
    rows.add(dateHeader);

    // Create pivot data: date -> station -> value
    final Map<String, Map<String, String>> pivotData = {};

    for (var record in records) {
      if (record.rainStation != null && record.rainfall != null) {
        pivotData.putIfAbsent(record.date, () => {});
        pivotData[record.date]![record.rainStation!] = record.rainfall!;
      }
    }

    // Sort dates
    final sortedDates = pivotData.keys.toList()..sort();

    // Build data rows
    for (var date in sortedDates) {
      final rowData = pivotData[date]!;
      final row = [date];

      for (var station in stations) {
        row.add(rowData[station] ?? '');
      }

      rows.add(row);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Save and share
    await _saveAndShare(csvString, 'rainfall_data_wide.csv');
  }

  // Export discharge data in wide format
  Future<void> exportDischargeData(List<DataRecord> records) async {
    final stations = StationMapping.getAllFlowStations();

    if (stations.isEmpty) {
      throw Exception('No discharge stations found');
    }

    // Build CSV content
    final List<List<dynamic>> rows = [];

    // --- HEADER GENERATION (8 Rows from V1) ---
    final List<String> regions = ['District'];
    final List<String> munis = ['Municipality/Ward'];
    final List<String> locs = ['Location Description'];
    final List<String> lats = ['Latitude (*N)'];
    final List<String> lons = ['Longitude (*E)'];
    final List<String> alts = ['Altitude (m)'];
    final List<String> collectors = ['Data collector (Name & Contact)'];
    final List<String> dateHeader = ['Date A.D.'];

    for (var st in stations) {
      final meta = StationMapping.metadata[st] ?? {};
      regions.add(meta['region'] ?? '');
      munis.add(meta['muni'] ?? '');
      locs.add(meta['loc'] ?? '');
      lats.add(meta['lat'] ?? '');
      lons.add(meta['lon'] ?? '');
      alts.add(meta['alt'] ?? '');
      collectors.add(meta['collector'] ?? '');
      dateHeader.add(st);
    }

    rows.add(regions);
    rows.add(munis);
    rows.add(locs);
    rows.add(lats);
    rows.add(lons);
    rows.add(alts);
    rows.add(collectors);
    rows.add(dateHeader);

    // Create pivot data: date -> station -> value
    final Map<String, Map<String, String>> pivotData = {};

    for (var record in records) {
      if (record.flowStation != null && record.discharge != null) {
        pivotData.putIfAbsent(record.date, () => {});
        pivotData[record.date]![record.flowStation!] = record.discharge!;
      }
    }

    // Sort dates
    final sortedDates = pivotData.keys.toList()..sort();

    // Build data rows
    for (var date in sortedDates) {
      final rowData = pivotData[date]!;
      final row = [date];

      for (var station in stations) {
        row.add(rowData[station] ?? '');
      }

      rows.add(row);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(rows);

    // Save and share
    await _saveAndShare(csvString, 'discharge_data_wide.csv');
  }

  // Helper method to save and share CSV file
  Future<void> _saveAndShare(String csvContent, String filename) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$filename';

      // Write file
      final file = File(path);
      await file.writeAsString(csvContent);

      // Share file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Data Export',
        text: 'Exported data from Data Collector app',
      );
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}
