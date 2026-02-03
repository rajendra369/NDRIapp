import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/firestore_service.dart';
import '../../../auth/domain/entities/collector.dart';
import 'collectors_event.dart';
import 'collectors_state.dart';

class CollectorsBloc extends Bloc<CollectorsEvent, CollectorsState> {
  final FirestoreService _firestoreService;
  StreamSubscription? _collectorsSubscription;

  CollectorsBloc({required FirestoreService firestoreService})
    : _firestoreService = firestoreService,
      super(CollectorsInitial()) {
    on<CollectorsFetchRequested>(_onCollectorsFetchRequested);
    on<CollectorAdded>(_onCollectorAdded);
    on<CollectorRemoved>(_onCollectorRemoved);
    on<CollectorUpdated>(_onCollectorUpdated);
    on<_CollectorsUpdated>(_onCollectorsUpdated);
  }

  void _onCollectorsFetchRequested(
    CollectorsFetchRequested event,
    Emitter<CollectorsState> emit,
  ) {
    emit(CollectorsLoading());
    _collectorsSubscription?.cancel();
    _collectorsSubscription = _firestoreService.getCollectorsStream().listen(
      (collectors) => add(_CollectorsUpdated(collectors)),
      onError: (e) => emit(CollectorsError(e.toString())),
    );
  }

  Future<void> _onCollectorAdded(
    CollectorAdded event,
    Emitter<CollectorsState> emit,
  ) async {
    try {
      await _firestoreService.addCollector(event.name);
      emit(CollectorOperationSuccess());
    } catch (e) {
      emit(CollectorsError(e.toString()));
    }
  }

  Future<void> _onCollectorRemoved(
    CollectorRemoved event,
    Emitter<CollectorsState> emit,
  ) async {
    try {
      await _firestoreService.removeCollector(event.id);
      emit(CollectorOperationSuccess());
    } catch (e) {
      emit(CollectorsError(e.toString()));
    }
  }

  Future<void> _onCollectorUpdated(
    CollectorUpdated event,
    Emitter<CollectorsState> emit,
  ) async {
    try {
      await _firestoreService.updateCollector(event.collector);
      emit(CollectorOperationSuccess());
    } catch (e) {
      emit(CollectorsError(e.toString()));
    }
  }

  void _onCollectorsUpdated(
    _CollectorsUpdated event,
    Emitter<CollectorsState> emit,
  ) {
    emit(CollectorsLoaded(event.collectors));
  }

  @override
  Future<void> close() {
    _collectorsSubscription?.cancel();
    return super.close();
  }
}

class _CollectorsUpdated extends CollectorsEvent {
  final List<Collector> collectors;
  const _CollectorsUpdated(this.collectors);
  @override
  List<Object?> get props => [collectors];
}
