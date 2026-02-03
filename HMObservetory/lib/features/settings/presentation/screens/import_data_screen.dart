import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/import_bloc.dart';
import '../bloc/import_event.dart';
import '../bloc/import_state.dart';

class ImportDataScreen extends StatelessWidget {
  const ImportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ImportBloc, ImportState>(
      listener: (context, state) {
        if (state is ImportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload Complete: ${state.count} records added'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ImportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import Historical Data'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<ImportBloc, ImportState>(
            builder: (context, state) {
              final isLoading = state is ImportLoading;
              final isUploading =
                  isLoading && state.message.contains('Uploading');
              final isPicking = isLoading && state.message.contains('Picking');

              String? selectedFileName;
              List<Map<String, dynamic>> parsedData = [];
              String? statusMessage;

              if (state is ImportFileSelected) {
                selectedFileName = state.fileName;
                parsedData = state.data;
                statusMessage = 'Found ${state.data.length} records';
              } else if (state is ImportLoading) {
                statusMessage = state.message;
              } else if (state is ImportSuccess) {
                statusMessage = 'Successfully uploaded ${state.count} records!';
              } else if (state is ImportError) {
                statusMessage = state.message;
              }

              return Column(
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
                          const Text(
                            '2. Ensure columns: Station ID, Date, Value',
                          ),
                          const Text('3. Review preview and upload'),
                          if (selectedFileName != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Selected: $selectedFileName',
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
                          onPressed: isLoading
                              ? null
                              : () => context.read<ImportBloc>().add(
                                  ImportFileRequested(),
                                ),
                          icon: isPicking
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.file_upload),
                          label: const Text('Select Excel File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: parsedData.isEmpty || isUploading
                              ? null
                              : () => context.read<ImportBloc>().add(
                                  ImportUploadRequested(parsedData),
                                ),
                          icon: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(
                            isUploading ? 'Uploading...' : 'Upload Data',
                          ),
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
                  if (statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color:
                              statusMessage.contains('Error') ||
                                  statusMessage.contains('failed')
                              ? Colors.red
                              : Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Data Preview Table
                  if (parsedData.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preview (${parsedData.length} records)',
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
                                itemCount:
                                    parsedData.length + 1, // +1 for header
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

                                  final item = parsedData[index - 1];
                                  final date = item['date'] as DateTime;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
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
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(date),
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
                  else if (isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
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
              );
            },
          ),
        ),
      ),
    );
  }
}
