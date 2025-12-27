part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);
}

class AuthLogoutRequested extends AuthEvent {}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String unit;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.unit,
  });

  @override
  List<Object> get props => [name, email, password, unit];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}
