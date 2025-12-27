import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/reports/presentation/bloc/report_bloc.dart';
import '../features/reports/presentation/pages/report_detail_page.dart';
import '../features/reports/domain/entities/report_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/domain/entities/user_entity.dart';

class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  bool _initialized = false;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'alerts_channel',
    'Acil Uyarılar',
    description: 'Acil durum uyarıları için bildirim kanalı',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    final messaging = FirebaseMessaging.instance;

    // iOS izinleri
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // iOS foreground gösterim seçenekleri
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Local notifications init (Android/iOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final reportId = resp.payload;
        if (reportId != null && reportId.isNotEmpty) {
          _navigateToReport(reportId);
        }
      },
    );
    // Android channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Token alın (gerekirse log/diagnostic için)
    await messaging.getToken();

    // Foreground mesajları bildirim olarak göster
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = notification?.android;
      final title = notification?.title ?? 'Acil Durum Uyarısı';
      final body = notification?.body ?? '';
      final reportId = message.data['reportId'] as String?;

      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
        ),
        payload: reportId,
      );

      // Uygulama içi banner/snackbar
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(title),
            action: reportId != null && reportId.isNotEmpty
                ? SnackBarAction(
                    label: 'Haritada Aç',
                    onPressed: () {
                      try {
                        ctx.read<ReportBloc>().add(ReportSelected(reportId));
                        // Ana sayfadaysa detay açılacak, değilse kullanıcı geri dönerek görebilir
                      } catch (_) {}
                    },
                  )
                : null,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // Bildirime tıklayarak açma (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleMessageOpen(initial);
    }

    _initialized = true;
  }

  Future<void> subscribeToAlerts() async {
    await FirebaseMessaging.instance.subscribeToTopic('alerts');
  }

  Future<void> unsubscribeFromAlerts() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('alerts');
  }

  void _handleMessageOpen(RemoteMessage message) {
    final reportId = message.data['reportId'] as String?;
    if (reportId != null && reportId.isNotEmpty) {
      _navigateToReport(reportId);
    }
  }

  void _navigateToReport(String reportId) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    try {
      // Önce mevcut stream'den bulmayı dene
      final bloc = ctx.read<ReportBloc>();
      final state = bloc.state;
      final report = state.reports.firstWhere(
        (e) => e.id == reportId,
        orElse: () => ReportEntity(
          id: '',
          title: '',
          description: '',
          type: ReportType.technical,
          status: ReportStatus.resolved,
          location: const LatLng(0, 0),
          createdAt: DateTime.now(),
          address: '',
          creatorUid: '',
          photoUrls: const [],
          isFollowed: false,
        ),
      );

      ReportEntity entity = report;
      if (entity.id.isEmpty) {
        // Firestore'dan tek seferlik yükle
        final snap = await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .get();
        final data = snap.data() as Map<String, dynamic>?;
        if (data != null) {
          final gp = data['location'];
          final ts = data['createdAt'];
          final photos =
              (data['photoUrls'] as List?)?.whereType<String>().toList() ??
              const [];
          entity = ReportEntity(
            id: snap.id,
            title: data['title'] as String? ?? 'Başlık',
            description: data['description'] as String? ?? '',
            type: _typeFromString(data['type'] as String?),
            status: _statusFromString(data['status'] as String?),
            location: gp is GeoPoint
                ? LatLng(gp.latitude, gp.longitude)
                : const LatLng(0, 0),
            createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
            address: data['address'] as String? ?? '',
            creatorUid: data['creatorUid'] as String? ?? '',
            photoUrls: photos,
            isFollowed: false,
          );
        }
      }

      if (entity.id.isEmpty) return;

      final authState = ctx.read<AuthBloc>().state;
      final isAdmin = authState.user?.role == UserRole.admin;
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: ctx.read<ReportBloc>(),
            child: ReportDetailPage(report: entity, isAdmin: isAdmin),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigate to report failed: $e');
    }
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
}
