import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_import_service.dart';
import '../services/auth_service.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  final DataImportService _importService = DataImportService();
  final AuthService _authService = AuthService();

  File? _selectedFile;
  List<Map<String, dynamic>> _parsedData = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _statusMessage;

  void _pickFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _parsedData = [];
      _selectedFile = null;
    });

    try {
      final file = await _importService.pickExcelFile();

      if (file != null) {
        setState(() => _selectedFile = file);
        await _parseFile(file);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _parseFile(File file) async {
    try {
      final data = await _importService.parseExcelFile(file);
      setState(() {
        _parsedData = data;
        _isLoading = false;
        if (data.isEmpty) {
          _statusMessage = 'No valid data found in file';
        } else {
          _statusMessage = 'Found ${data.length} records';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error parsing file: $e';
      });
    }
  }

  void _uploadData() async {
    if (_parsedData.isEmpty) return;

    final collector = _authService.currentCollector ?? 'Unknown';

    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading ${_parsedData.length} records...';
    });

    try {
      final count = await _importService.uploadRecords(_parsedData, collector);

      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = 'Successfully uploaded $count records!';
          _parsedData = [];
          _selectedFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload Complete: $count records added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = 'Upload failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Historical Data'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Select an Excel (.xlsx) file'),
                    const Text('2. Ensure columns: Station ID, Date, Value'),
                    const Text('3. Review preview and upload'),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Selected: ${_selectedFile!.path.split(Platform.pathSeparator).last}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _isUploading ? null : _pickFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Select Excel File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _parsedData.isEmpty || _isUploading
                        ? null
                        : _uploadData,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Status Message
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color:
                        _statusMessage!.contains('Error') ||
                            _statusMessage!.contains('failed')
                        ? Colors.red
                        : Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Data Preview Table
            if (_parsedData.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview (${_parsedData.length} records)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _parsedData.length + 1, // +1 for header
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Header
                              return Container(
                                color: Colors.grey[200],
                                padding: const EdgeInsets.all(12),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Station ID',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Date',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Value',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final item = _parsedData[index - 1];
                            final date = item['date'] as DateTime;

                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                                color: (index % 2 == 0)
                                    ? Colors.white
                                    : Colors.grey[50],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(item['stationId']),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      DateFormat('yyyy-MM-dd').format(date),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      item['value'].toString(),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No data to display',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
