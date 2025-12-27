import 'dart:async';
import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../domain/entities/report_entity.dart';
import '../domain/repositories/report_repository.dart';

class ReportRepositoryMock implements ReportRepository {
  ReportRepositoryMock() {
    _seed();
  }

  final List<ReportEntity> _items = [];

  void _seed() {
    if (_items.isNotEmpty) return;
    final now = DateTime.now();
    final rnd = Random(42);
    final baseLat = 39.9069;
    final baseLng = 41.2779;

    List<ReportEntity> seeds = [
      ReportEntity(
        id: 'r1',
        title: 'Sağlık: Baygın öğrenci',
        description: 'Mühendislik fakültesi kantininde bir öğrenci bayıldı.',
        type: ReportType.health,
        status: ReportStatus.open,
        location: LatLng(baseLat + 0.003, baseLng + 0.002),
        createdAt: now.subtract(const Duration(minutes: 25)),
        address: 'Mühendislik Fakültesi Kantin',
        creatorUid: 'mock_user',
      ),
      ReportEntity(
        id: 'r2',
        title: 'Güvenlik: Şüpheli paket',
        description: 'Kütüphane girişinde şüpheli paket bildirildi.',
        type: ReportType.security,
        status: ReportStatus.reviewing,
        location: LatLng(baseLat - 0.001, baseLng + 0.0015),
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
        address: 'Merkez Kütüphane',
        creatorUid: 'mock_user',
      ),
      ReportEntity(
        id: 'r3',
        title: 'Çevre: Su kaçağı',
        description: 'Yurt blok C önünde su patlağı.',
        type: ReportType.environment,
        status: ReportStatus.open,
        location: LatLng(baseLat + 0.004, baseLng - 0.002),
        createdAt: now.subtract(const Duration(hours: 3)),
        address: 'Yurtlar Bölgesi',
        creatorUid: 'mock_user',
      ),
      ReportEntity(
        id: 'r4',
        title: 'Kayıp eşya: Cüzdan',
        description: 'Siyah deri cüzdan spor salonunda bulundu.',
        type: ReportType.lostFound,
        status: ReportStatus.resolved,
        location: LatLng(baseLat - 0.0025, baseLng - 0.0015),
        createdAt: now.subtract(const Duration(hours: 6, minutes: 20)),
        address: 'Spor Salonu',
        creatorUid: 'mock_user',
      ),
      ReportEntity(
        id: 'r5',
        title: 'Teknik: Elektrik kesintisi',
        description: 'Fen fakültesi koridorlarında aydınlatma yok.',
        type: ReportType.technical,
        status: ReportStatus.reviewing,
        location: LatLng(baseLat + 0.0018, baseLng - 0.0022),
        createdAt: now.subtract(const Duration(minutes: 50)),
        address: 'Fen Fakültesi',
        creatorUid: 'mock_user',
      ),
    ];

    for (var i = 0; i < seeds.length; i++) {
      final markFollow = rnd.nextBool();
      _items.add(seeds[i].copyWith(isFollowed: markFollow));
    }
  }

  @override
  Stream<List<ReportEntity>> streamReports() async* {
    yield List.unmodifiable(_items);
  }

  @override
  Future<ReportEntity> createReport(
    ReportEntity report, {
    List<String> imagePaths = const [],
  }) async {
    final newReport = report.copyWith(
      isFollowed: false,
      photoUrls: const [],
    );
    _items.insert(0, newReport);
    return newReport;
  }

  @override
  Future<ReportEntity?> updateStatus(String id, ReportStatus status) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    final updated = _items[idx].copyWith(status: status);
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<ReportEntity?> toggleFollow(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    final updated = _items[idx].copyWith(isFollowed: !_items[idx].isFollowed);
    _items[idx] = updated;
    return updated;
  }

  // --- EKLENEN YENİ METODLAR ---

  @override
  Future<void> deleteReport(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> updateReportDescription(String id, String description) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(description: description);
    }
  }
}