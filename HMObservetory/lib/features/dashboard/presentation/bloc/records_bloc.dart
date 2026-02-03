import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/data_record.dart';
import '../../data/datasources/firestore_service.dart';
import 'records_event.dart';
import 'records_state.dart';

class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _recordsSubscription;

  RecordsBloc({required FirestoreService firestoreService})
    : _firestoreService = firestoreService,
      super(RecordsInitial()) {
    on<RecordSaveRequested>(_onRecordSaveRequested);
    on<RecordsFetchRequested>(_onRecordsFetchRequested);
    on<RecordsClearRequested>(_onRecordsClearRequested);
    on<_RecordsUpdated>(_onRecordsUpdated);
    on<_RecordsErrorOccurred>(_onRecordsErrorOccurred);
  }

  Future<void> _onRecordSaveRequested(
    RecordSaveRequested event,
    Emitter<RecordsState> emit,
  ) async {
    emit(RecordsLoading());
    try {
      await _firestoreService.saveRecord(event.record);
      emit(RecordSaveSuccess());
      // Re-trigger fetch to update list if needed, or rely on stream
    } catch (e) {
      emit(RecordsError('Failed to save record: $e'));
    }
  }

  void _onRecordsFetchRequested(
    RecordsFetchRequested event,
    Emitter<RecordsState> emit,
  ) {
    emit(RecordsLoading());
    _recordsSubscription?.cancel();
    _recordsSubscription = _firestoreService.getRecordsStream().listen(
      (records) => add(_RecordsUpdated(records)),
      onError: (e) => add(_RecordsErrorOccurred(e.toString())),
    );
  }

  // Internal events for handling stream updates
  void _onRecordsUpdated(_RecordsUpdated event, Emitter<RecordsState> emit) {
    emit(RecordsLoaded(event.records));
  }

  void _onRecordsErrorOccurred(
    _RecordsErrorOccurred event,
    Emitter<RecordsState> emit,
  ) {
    emit(RecordsError(event.message));
  }

  Future<void> _onRecordsClearRequested(
    RecordsClearRequested event,
    Emitter<RecordsState> emit,
  ) async {
    final currentState = state;
    emit(RecordsLoading());
    try {
      await _firestoreService.clearAllRecords();
      // Usually the stream will update this, but we can emit success or initial
    } catch (e) {
      emit(RecordsError('Failed to clear records: $e'));
      if (currentState is RecordsLoaded) {
        emit(currentState);
      }
    }
  }

  @override
  Future<void> close() {
    _recordsSubscription?.cancel();
    return super.close();
  }
}

// Private helper events
class _RecordsUpdated extends RecordsEvent {
  final List<DataRecord> records;
  const _RecordsUpdated(this.records);
  @override
  List<Object?> get props => [records];
}

class _RecordsErrorOccurred extends RecordsEvent {
  final String message;
  const _RecordsErrorOccurred(this.message);
  @override
  List<Object?> get props => [message];
}

// Add these to records_bloc.dart directly as they are internal.
// Wait, I should implement the handlers for these internal events in the constructor.
