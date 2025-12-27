import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';

import '../domain/entities/report_entity.dart';
import '../domain/repositories/report_repository.dart';

class ReportRepositoryFirestore implements ReportRepository {
  ReportRepositoryFirestore({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       // Bucket google-services.json'daki storage_bucket ile eşleşmeli
       _storage =
           storage ??
           FirebaseStorage.instanceFor(
             bucket: 'mobilprojesi1.firebasestorage.app',
           );

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  @override
  Stream<List<ReportEntity>> streamReports() {
    final reportsRef = _db
        .collection('reports')
        .orderBy('createdAt', descending: true);
    return reportsRef.snapshots().asyncMap((snapshot) async {
      final followIds = await _fetchFollowedIds();
      return snapshot.docs
          .map((doc) => _fromDoc(doc, followIds))
          .whereType<ReportEntity>()
          .toList();
    });
  }

  @override
  Future<ReportEntity> createReport(
    ReportEntity report, {
    List<String> imagePaths = const [],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Giriş yapmalısınız');
    final ref = _db.collection('reports').doc();
    final downloadUrls = await _uploadImages(ref.id, imagePaths);

    await ref.set({
      'title': report.title,
      'description': report.description,
      'type': _typeToString(report.type),
      'status': _statusToString(report.status),
      'address': report.address,
      'location': GeoPoint(report.location.latitude, report.location.longitude),
      'creatorUid': uid,
      'areaTag': 'campus',
      if (downloadUrls.isNotEmpty) 'photoUrls': downloadUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final doc = await ref.get();
    final entity = _fromDoc(doc, await _fetchFollowedIds());
    if (entity == null) throw Exception('Rapor oluşturulamadı');
    return entity;
  }

  @override
  Future<ReportEntity?> updateStatus(String id, ReportStatus status) async {
    await _db.collection('reports').doc(id).set({
      'status': _statusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final doc = await _db.collection('reports').doc(id).get();
    final entity = _fromDoc(doc, await _fetchFollowedIds());
    return entity;
  }

  @override
  Future<ReportEntity?> toggleFollow(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Giriş yapmalısınız');
    final followId = '${id}_$uid';
    final ref = _db.collection('report_follows').doc(followId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'reportId': id,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final doc = await _db.collection('reports').doc(id).get();
    return _fromDoc(doc, await _fetchFollowedIds());
  }

  Future<Set<String>> _fetchFollowedIds() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return <String>{};
    final snap = await _db
        .collection('report_follows')
        .where('uid', isEqualTo: uid)
        .get();
    return snap.docs
        .map((d) => d.data()['reportId'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  ReportEntity? _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Set<String> followIds,
  ) {
    final data = doc.data();
    if (data == null) return null;
    final ts = data['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    final geo = data['location'];
    final gp = geo is GeoPoint ? geo : null;
    final photos =
        (data['photoUrls'] as List?)?.whereType<String>().toList() ?? const [];
    return ReportEntity(
      id: doc.id,
      title: data['title'] as String? ?? 'Başlık',
      description: data['description'] as String? ?? '',
      type: _typeFromString(data['type'] as String?),
      status: _statusFromString(data['status'] as String?),
      location: gp != null
          ? LatLng(gp.latitude, gp.longitude)
          : const LatLng(39.9069, 41.2779),
      createdAt: created,
      address: data['address'] as String? ?? '',
      creatorUid: data['creatorUid'] as String? ?? '',
      photoUrls: photos,
      isFollowed: followIds.contains(doc.id),
    );
  }

  ReportType _typeFromString(String? type) {
    switch (type) {
      case 'health':
        return ReportType.health;
      case 'security':
        return ReportType.security;
      case 'environment':
        return ReportType.environment;
      case 'lostFound':
        return ReportType.lostFound;
      case 'technical':
      default:
        return ReportType.technical;
    }
  }

  String _typeToString(ReportType type) {
    switch (type) {
      case ReportType.health:
        return 'health';
      case ReportType.security:
        return 'security';
      case ReportType.environment:
        return 'environment';
      case ReportType.lostFound:
        return 'lostFound';
      case ReportType.technical:
        return 'technical';
    }
  }

  String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.open:
        return 'open';
      case ReportStatus.reviewing:
        return 'reviewing';
      case ReportStatus.resolved:
        return 'resolved';
    }
  }

  ReportStatus _statusFromString(String? status) {
    switch (status) {
      case 'open':
        return ReportStatus.open;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'resolved':
      default:
        return ReportStatus.resolved;
    }
  }

  Future<List<String>> _uploadImages(
    String reportId,
    List<String> imagePaths,
  ) async {
    if (imagePaths.isEmpty) return [];
    final urls = <String>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final file = File(path);
      if (!file.existsSync()) continue;
      final ext = path.split('.').last;
      final ref = _storage.ref(
        'reports/$reportId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext',
      );
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  @override
  Future<void> updateReportDescription(String id, String description) async {
    await _db.collection('reports').doc(id).set({
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteReport(String id) async {
    await _db.collection('reports').doc(id).delete();
  }
}
