import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum ReportType { health, security, environment, lostFound, technical }

enum ReportStatus { open, reviewing, resolved }

class ReportEntity extends Equatable {
  const ReportEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.address,
    required this.creatorUid,
    this.photoUrls = const [],
    this.isFollowed = false,
  });

  final String id;
  final String title;
  final String description;
  final ReportType type;
  final ReportStatus status;
  final LatLng location;
  final DateTime createdAt;
  final String address;
  final String creatorUid;
  final List<String> photoUrls;
  final bool isFollowed;

  // Tüm alanları güncelleyebilen tam kapsamlı copyWith metodu
  ReportEntity copyWith({
    String? id,
    String? title,
    String? description,
    ReportType? type,
    ReportStatus? status,
    LatLng? location,
    DateTime? createdAt,
    String? address,
    String? creatorUid,
    List<String>? photoUrls,
    bool? isFollowed,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      creatorUid: creatorUid ?? this.creatorUid,
      photoUrls: photoUrls ?? this.photoUrls,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        status,
        location,
        createdAt,
        address,
        creatorUid,
        photoUrls,
        isFollowed,
      ];
}