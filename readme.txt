PROJECT OVERVIEW
- Flutter çoklu platform (Android/iOS/Web/Desktop) uygulaması; kampüs ihbar/rapor yönetimi.
- Teknolojiler: Flutter 3.x, Dart 3.x, Firebase (Auth, Firestore, Storage, Messaging), flutter_map (OSM), BLoC state management.

PREREQUISITES
- Flutter SDK yüklü ve PATH’e ekli.
- Android SDK / Xcode platform araçları kurulu.
- Firebase projesi: android/app/google-services.json ve ios/Runner/GoogleService-Info.plist dosyaları yerleştirilmiş olmalı.
- Web push için Firebase Cloud Messaging konfigürasyonu (manifest ve service worker) gerekiyorsa eklenmeli.

KURULUM VE ÇALIŞTIRMA
- Bağımlılıkları çek: flutter pub get
- Android debug çalıştır: flutter run
- Release APK: flutter build apk --release (çıktı: build/app/outputs/flutter-apk/app-release.apk)
- iOS: flutter build ios (Xcode imzalama gerekir)
- Functions (uyarı yayını) için: cd functions && npm install && firebase deploy --only functions

MİMARİ ÖZETİ
- Ana giriş: lib/main.dart
  - Firebase.initializeApp()
  - Repository ve BLoC provider’ları kurulur (AuthBloc, ReportBloc).
  - Auth durumuna göre HomePage veya LoginPage gösterilir.
  - MessagingService initialize edilir ve alerts konusuna abone olunur.
- Navigasyon anahtarı: lib/navigation.dart (rootNavigatorKey)
- Push/Bildirim servisi: lib/services/messaging_service.dart
  - Firebase Messaging başlatma, topic aboneliği (alerts), foreground bildirimleri local notification ile gösterme, snackbar/banner ve bildirime tıklayınca rapora gitme akışı.
- Özellikler klasörü (features): auth, reports, home altına ayrılmıştır; her biri domain/data/presentation katmanlarına sahip.

DOSYA DETAYLARI (ANA/LAYERS)

lib/main.dart
- Uygulama girişi; çoklu repository ve BLoC provider; tema; _AuthWrapper ile auth durumuna göre yönlendirme; messaging background handler.

lib/navigation.dart
- Uygulama genelinde kullanılacak root Navigator key (bildirim tıklamalarından sayfa açmak için).

lib/services/messaging_service.dart
- Firebase Messaging init, izin isteme, topic subscribe/unsubscribe.
- Foreground bildirimlerini flutter_local_notifications ile gösterir; snackbar/banner tetikler.
- Notification tap veya snackbar aksiyonuyla reportId üzerinden ReportDetailPage’e navigasyon; eğer stream’de yoksa Firestore’dan tek seferlik rapor yükler.

features/auth/
- domain/entities/user_entity.dart: Kullanıcı modeli (id, email, name, unit, role).
- domain/repositories/auth_repository.dart: Auth kontratı (login/register/logout/current user, getAllUsers, updateUserRole).
- data/repositories/auth_repository_impl.dart: Firebase Auth + Firestore tabanlı implementasyon; user doc oluşturma, rol okuma/yazma, tüm kullanıcıları listeleme, rol güncelleme.
- presentation/bloc/auth_bloc.dart (+ auth_event.dart, auth_state.dart): Auth durum yönetimi; login/register/logout, forgot password akışları.
- presentation/pages/login_page.dart: Giriş ekranı; register/forgot navigasyon; admin kurulum girişi kaldırıldı.
- presentation/pages/register_page.dart: Kayıt formu; isim, email, şifre, birim.
- presentation/pages/forgot_password_page.dart: Şifre sıfırlama isteği.
- presentation/pages/profile_page.dart: Kullanıcı bilgileri, ilanlarım listesi, ayarlar; admin ise Kullanıcı Yönetimi kartı gösterir.
- presentation/pages/user_management_page.dart: Yalnız admin erişimi; tüm kullanıcıları listeler ve rol (admin/user) değiştirir.

features/reports/
- domain/entities/report_entity.dart: Rapor modeli (title, description, type, status, location, creatorUid, photoUrls, isFollowed).
- domain/repositories/report_repository.dart: Rapor işlemleri kontratı (stream, create, updateStatus, toggleFollow, updateDescription, delete).
- data/report_repository_firestore.dart: Firestore ve Storage implementasyonu; rapor oluşturma, durum güncelleme, takip, açıklama güncelleme, silme; image upload bucket’ı sabit tanımlı.
- presentation/bloc/report_bloc.dart (+ report_event.dart, report_state.dart): Rapor stream’ini dinler; filtre, arama, seçim, takip, oluşturma, durum/description güncelleme, silme.
- presentation/pages/report_detail_page.dart: Rapor detay ekranı; admin menüsü (durum, açıklama düzenleme, silme, acil uyarı); sahibi menüsü (açıklama düzenleme, silme); fotoğraf galerisi.
- presentation/pages/create_report_page.dart: Yeni rapor oluşturma formu; konum, fotoğraf, açıklama, tip, durum (varsayılan open), storage upload.

features/home/presentation/pages/home_page.dart
- Ana ekran; harita (flutter_map + OSM), filtreler, arama, liste, marker seçimi, detay görünümü.
- Marker tıklama veya listedeki kart tıklaması detay view açar (tek pin, geniş kart).
- Takip et/çık butonu; filtre chips; admin için “Yetki Alanım” seçim seçeneği; profil ve yeni rapor butonları.

Diğer platform klasörleri
- android/: Gradle yapılandırması; firebase google-services.json gerekir; desugaring açık.
- ios/: Xcode/Runner yapılandırması; GoogleService-Info.plist gerekir; bildirimler için APNs ayarı yapılmalı.
- web/: index.html, manifest, icons; FCM kullanılıyorsa web service worker eklenmeli.
- functions/: Cloud Functions (Node 18); index.js -> alerts koleksiyonuna yeni kayıt eklenince alerts topic’e FCM bildirimi gönderir; package.json bağımlılıkları içerir.

FIREBASE VE GÜVENLİK
- Firestore koleksiyonları: users, reports, report_follows, alerts.
- Önerilen kurallar: (özet)
  - users: sahibi veya admin okur/yazar.
  - reports: girişli herkes okur; oluşturma creatorUid==auth.uid; update/delete admin veya sahibi.
  - report_follows: kullanıcı kendi takip kaydını okur/yazar/siler; admin hepsini okur/yazar; update kapalı.
  - alerts: sadece admin create (opsiyonel read admin); update/delete kapalı.
- Roller: user, admin (users/{uid}.role alanı).

ÇALIŞTIRMA/TEST
- Komutlar:
  - flutter run
  - flutter test (widget/unit testler için)
  - flutter build apk --release
  - firebase deploy --only functions (Cloud Functions için)
- Bildirim testleri: Admin rapor detayında “Acil Durum Uyarısı” oluştur -> alerts doc -> Function alerts topic’e FCM yollar -> cihaz alerts konusuna abone olduğu için bildirim gelir.

NOTLAR
- Derleme uyarıları: flutter_local_notifications nedeniyle coreLibraryDesugaring aktiftir (android/app/build.gradle.kts). Android Studio/Gradle uyarıları (source/target 8) karşınıza çıkabilir; yeni AGP ile güncellenebilir.
- Eğer storage bucket veya Firebase proje adı değişirse report_repository_firestore.dart içindeki bucket adını ve firebase konfig dosyalarını güncelleyin.
- iOS için push bildirimleri: APNs sertifikası/anahtarı ve Xcode capability ayarı gereklidir.
