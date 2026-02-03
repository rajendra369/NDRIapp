import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/data_import_service.dart';
import 'import_event.dart';
import 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final DataImportService _importService;

  ImportBloc({required DataImportService importService})
    : _importService = importService,
      super(ImportInitial()) {
    on<ImportFileRequested>(_onImportFileRequested);
    on<ImportUploadRequested>(_onImportUploadRequested);
  }

  Future<void> _onImportFileRequested(
    ImportFileRequested event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportLoading('Picking file...'));
    try {
      final result = await _importService.pickAndParseExcel();
      if (result != null) {
        emit(ImportFileSelected(result['fileName'], result['data']));
      } else {
        emit(ImportInitial());
      }
    } catch (e) {
      emit(ImportError('Failed to pick file: $e'));
    }
  }

  Future<void> _onImportUploadRequested(
    ImportUploadRequested event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportLoading('Uploading data...'));
    try {
      await _importService.uploadToFirestore(event.data);
      emit(ImportSuccess(event.data.length));
    } catch (e) {
      emit(ImportError('Upload failed: $e'));
    }
  }
}
