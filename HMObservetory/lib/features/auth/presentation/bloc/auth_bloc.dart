import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    if (_authService.isLoggedIn) {
      emit(AuthAuthenticated(_authService.currentCollector!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // Simulate network delay as requested in original code
    await Future.delayed(const Duration(milliseconds: 500));

    final success = _authService.loginAsCollector(
      event.collector,
      event.password,
    );

    if (success) {
      emit(AuthAuthenticated(event.collector));
    } else {
      emit(const AuthFailure('Invalid password'));
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _authService.logout();
    emit(AuthUnauthenticated());
  }
}
