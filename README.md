# MobilProjesi1 – Firebase Kimlik Doğrulama

Uygulama, Firebase Authentication ile e-posta/şifre girişi ve kayıt akışını kullanır. Bloc mimarisi ile yönetiliyor.

## Firebase kurulumu
1) Firebase projesi: `mobilprojesi1` projesini oluşturduğunuzdan emin olun, Email/Password sağlayıcısını etkinleştirin.
2) Android yapılandırması:
	- Firebase Console → Android uygulaması ekleyin, paket adı: `com.example.mobile_project` (kendi paket adınızı kullanın).
	- `google-services.json` dosyasını indirip `android/app/google-services.json` konumuna ekleyin.
	- `android/app/build.gradle.kts` içinde `com.google.gms.google-services` eklentisi zaten tanımlı.
	- `android/settings.gradle.kts` içinde Google Services eklentisi sürümü tanımlı.
3) iOS yapılandırması (varsa):
	- iOS uygulaması ekleyin, `GoogleService-Info.plist` dosyasını `ios/Runner/GoogleService-Info.plist` konumuna ekleyin.
4) (Önerilen) FlutterFire ile seçenek dosyası üretmek için:
	```powershell
	Push-Location 'D:\Yazilim\mobile_project'
	flutterfire configure --project=mobilprojesi1 --platforms=android,ios,web
	Pop-Location
	```
	Bu komut `lib/firebase_options.dart` dosyasını üretir; isterseniz `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` kullanacak şekilde `lib/main.dart` dosyasını güncelleyebilirsiniz.

## Çalıştırma
```powershell
Push-Location 'D:\Yazilim\mobile_project'
flutter run
Pop-Location
```

## Notlar
- Şifre sıfırlama, Firebase üzerinden e-posta gönderir.
- Admin rolü için ek claim/alan mantığı eklenmemiştir; varsayılan olarak tüm kullanıcılar `UserRole.user` döner.

## Dokümantasyon
- Gereksinimler ve PDF özeti: `docs/requirements.md`
- Mimari özeti: `docs/architecture.md`
- Ekran listesi: `docs/screens.md`
- Acil uyarı sistemi: `docs/alerts.md`
