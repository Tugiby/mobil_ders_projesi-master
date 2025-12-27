import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/reports/data/report_repository_firestore.dart';
import 'features/reports/domain/repositories/report_repository.dart';
import 'features/reports/presentation/bloc/report_bloc.dart';
import 'services/messaging_service.dart';
import 'navigation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Push bildirimleri için başlatma
  await MessagingService.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda notification payload'lı mesajları sistem gösterir.
  // Veri işlemek isterseniz burada yapabilirsiniz.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        RepositoryProvider<ReportRepository>(
          create: (_) => ReportRepositoryFirestore(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(context.read<AuthRepository>())
                  ..add(const AuthAppStarted()),
          ),
          BlocProvider<ReportBloc>(
            create: (context) =>
                ReportBloc(context.read<ReportRepository>())
                  ..add(ReportLoadRequested()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, next) => prev.status != next.status,
          listener: (context, state) async {
            if (state.status == AuthStatus.authenticated) {
              await MessagingService.instance.subscribeToAlerts();
            } else if (state.status == AuthStatus.initial) {
              await MessagingService.instance.unsubscribeFromAlerts();
            }
          },
          child: MaterialApp(
            title: 'Campus Report App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            navigatorKey: rootNavigatorKey,
            home: const _AuthWrapper(),
          ),
        ),
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          return HomePage(user: state.user!);
        }
        return const LoginPage();
      },
    );
  }
}
