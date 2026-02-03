import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String collector;
  final String password;

  const AuthLoginRequested({required this.collector, required this.password});

  @override
  List<Object?> get props => [collector, password];
}

class AuthLogoutRequested extends AuthEvent {}
