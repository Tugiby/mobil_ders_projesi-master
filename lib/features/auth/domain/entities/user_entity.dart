import 'package:equatable/equatable.dart';

enum UserRole { admin, user }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String unit; // Birim bilgisi

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.unit,
  });

  @override
  List<Object?> get props => [id, email, role];
}