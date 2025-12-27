import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance {
    // Oturum süresi: 3600 gün (en uzun Firebase Auth session)
    _auth.setPersistence(Persistence.LOCAL);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserEntity _toUserEntity(User user, Map<String, dynamic>? data) {
    final role = _mapRole(data?['role'] as String?);
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      name: data?['name'] as String? ?? user.displayName ?? 'Kullanıcı',
      role: role,
      unit: data?['unit'] as String? ?? 'Birim',
    );
  }

  UserRole _mapRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  Future<void> _ensureUserDoc(User user, {String? name, String? unit}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'name': name ?? user.displayName ?? 'Kullanıcı',
        'role': 'user',
        'unit': unit ?? 'Birim',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (name != null || unit != null) {
      await ref.set({
        if (name != null) 'name': name,
        if (unit != null) 'unit': unit,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Kullanıcı bulunamadı');
      await _ensureUserDoc(user);
      final data = (await _db.collection('users').doc(user.uid).get()).data();
      return _toUserEntity(user, data);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Giriş başarısız';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Yanlış şifre';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email formatı';
          break;
        case 'user-disabled':
          errorMessage = 'Kullanıcı hesabı devre dışı';
          break;
        case 'invalid-credential':
          errorMessage = 'Email veya şifre hatalı';
          break;
        default:
          errorMessage = e.message ?? 'Giriş başarısız';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    String unit,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Kullanıcı oluşturulamadı');
      await user.updateDisplayName(name);
      await _ensureUserDoc(user, name: name, unit: unit);
      final data = (await _db.collection('users').doc(user.uid).get()).data();
      return _toUserEntity(user, data);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Kayıt başarısız';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu email zaten kullanılıyor';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz email formatı';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/şifre girişi etkin değil';
          break;
        default:
          errorMessage = e.message ?? 'Kayıt başarısız';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Şifre sıfırlama başarısız');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final data = (await _db.collection('users').doc(user.uid).get()).data();
    return _toUserEntity(user, data);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    final users = <UserEntity>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Create a dummy User object for _toUserEntity
      final userEntity = UserEntity(
        id: doc.id,
        email: data['email'] as String? ?? '',
        name: data['name'] as String? ?? 'Kullanıcı',
        role: _mapRole(data['role'] as String?),
        unit: data['unit'] as String? ?? 'Birim',
      );
      users.add(userEntity);
    }
    return users;
  }

  @override
  Future<void> updateUserRole(String userId, UserRole role) async {
    final roleString = role == UserRole.admin ? 'admin' : 'user';
    await _db.collection('users').doc(userId).set({
      'role': roleString,
    }, SetOptions(merge: true));
  }
}
