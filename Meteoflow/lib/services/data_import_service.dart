import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataImportService {
  /// Pick an Excel file from the device
  Future<File?> pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Parse the Excel file and extract data records
  /// Returns a list of potential DataRecord objects
  Future<List<Map<String, dynamic>>> parseExcelFile(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    // Assume data is in the first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];

    if (sheet == null) {
      throw Exception('Sheet is empty or invalid');
    }

    List<Map<String, dynamic>> parsedData = [];

    // Find header row
    int dataStartIndex = 0;

    for (int i = 0; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      // Access the first cell's data
      var firstCellData = row[0];
      var firstCellValue = firstCellData?.value;

      String? firstCellStr;

      if (firstCellValue is TextCellValue) {
        firstCellStr = firstCellValue.value.toString();
      } else if (firstCellValue != null) {
        firstCellStr = firstCellValue.toString();
      }

      if (firstCellStr != null &&
          (firstCellStr.toLowerCase().contains('station') ||
              firstCellStr.toLowerCase().contains('id'))) {
        dataStartIndex = i + 1;
        break;
      }
    }

    // Parse data rows
    for (int i = dataStartIndex; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.length < 3) continue; // Skip incomplete rows

      try {
        // Safe access to cell values
        var idVal = row[0]?.value;
        var dateVal = row[1]?.value;
        var valVal = row[2]?.value;

        if (idVal == null || dateVal == null || valVal == null) continue;

        // 1. Station ID
        String stationId = '';
        if (idVal is TextCellValue) {
          stationId = idVal.value.toString().trim();
        } else {
          stationId = idVal.toString().trim();
        }

        // 2. Date
        DateTime? date;
        if (dateVal is DateCellValue) {
          date = dateVal.asDateTimeLocal();
        } else if (dateVal is TextCellValue) {
          date = DateTime.tryParse(dateVal.value.toString());
        } else {
          date = DateTime.tryParse(dateVal.toString());
        }

        if (date == null) continue;

        // 3. Value (Rain/Flow)
        double? value;
        if (valVal is DoubleCellValue) {
          value = valVal.value;
        } else if (valVal is IntCellValue) {
          value = valVal.value.toDouble();
        } else if (valVal is TextCellValue) {
          value = double.tryParse(valVal.value.toString());
        } else {
          value = double.tryParse(valVal.toString());
        }

        if (value == null) continue;

        parsedData.add({
          'stationId': stationId,
          'date': date,
          'value': value,
          'isValid': true,
        });
      } catch (e) {
        debugPrint('Error parsing row $i: $e');
      }
    }

    return parsedData;
  }

  /// Convert parsed data to DataRecord objects and Upload to Firestore
  /// Returns count of successfully uploaded records
  Future<int> uploadRecords(
    List<Map<String, dynamic>> data,
    String collectorName,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final batchSize = 500; // Firestore batch limit
    int successCount = 0;

    // Process in batches
    for (var i = 0; i < data.length; i += batchSize) {
      final batch = firestore.batch();
      var end = (i + batchSize < data.length) ? i + batchSize : data.length;
      var currentBatch = data.sublist(i, end);

      for (var item in currentBatch) {
        try {
          String stationId = item['stationId'];
          DateTime date = item['date'];
          double value = item['value'];

          // Create DataRecord object
          // ID format: STATION_TIMESTAMP (to prevent duplicates)
          String docId = '${stationId}_${date.millisecondsSinceEpoch}';

          final recordRef = firestore.collection('data_records').doc(docId);

          batch.set(recordRef, {
            'stationId': stationId,
            'timestamp': Timestamp.fromDate(date),
            'value': value,
            'collectorId': collectorName,
            'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
            'uploadedAt': FieldValue.serverTimestamp(),
            'notes': 'Imported from Excel',
          }, SetOptions(merge: true));

          successCount++;
        } catch (e) {
          debugPrint('Error adding to batch: $e');
          successCount--; // Decrement if failed (simplified logic)
        }
      }

      await batch.commit();
    }

    return successCount;
  }
}
