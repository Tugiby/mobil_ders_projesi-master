# Deployment Rehberi

Uygulamayı Android, iOS, Web ve masaüstü platformlarında derleyip yayınlamak için adımlar.

## Ön Koşullar

- Flutter SDK 3.10.1+ (`flutter --version`)
- Android SDK (Android Studio veya CLI)
- Xcode (macOS/iOS)
- Firebase projesi: `mobilprojesi1`
- google-services.json (Android)
- GoogleService-Info.plist (iOS)
- Firebase Cloud Messaging yapılandırması

## Android

### Debug APK
```bash
flutter pub get
flutter run
```

### Release APK
```bash
flutter build apk --release
# Çıktı: build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Hazırlığı (İsteğe Bağlı)
```bash
# Keystore oluştur (ilk kez)
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# android/local.properties dosyasını güncelleyin:
# storeFile=~/.android/key.jks
# storePassword=...
# keyPassword=...
# keyAlias=key

flutter build appbundle --release
# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

## iOS

### Simulator
```bash
flutter run -d "iPhone 14"
```

### Release ipa (Testflight/AppStore)
```bash
flutter build ipa --release
# Xcode projesi düzenleme gerekebilir: ios/Runner.xcworkspace açın
# Signing & Capabilities: Team seçin, gerekli certificate'ler ekleyin
```

### Notlar
- APNs sertifikası ve push notification capability'si gerekli
- Ad Hoc dağıtım için Provisioning Profile düzenlemesi

## Web

### Debug
```bash
flutter run -d chrome
```

### Release Build
```bash
flutter build web --release
# Çıktı: build/web/ (Nginx/Apache/S3 vb. ile host edin)
```

## Cloud Functions Deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

Veya (tüm firebase config)
```bash
firebase deploy
```

Gereksinimler:
- Firebase CLI: `npm install -g firebase-tools`
- `firebase login` ile giriş yapılmış

## Firestore Security Rules

Production ortamında şu kuralları uygulayın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar: sadece kendi bilgileri görebilir
    match /users/{uid} {
      allow read: if request.auth.uid == uid;
      allow update: if request.auth.uid == uid;
      allow create: if request.auth.uid == uid;
    }

    // Raporlar: herkes okuyabilir, giriş yapılanlar oluşturabilir, yönetici/sahip güncelleyebilir
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.creatorUid || 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow delete: if request.auth.uid == resource.data.creatorUid || 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Takipçiler: kullanıcı kendi takip kaydını yönetebilir
    match /report_follows/{followId} {
      allow read: if request.auth.uid == resource.data.uid;
      allow create, delete: if request.auth.uid == resource.data.uid;
    }

    // Uyarılar: sadece admin oluşturabilir, herkes okuyabilir
    match /alerts/{alertId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow update, delete: if false;
    }
  }
}
```

Firebase Console → Firestore → Rules sekmesinde yapıştırıp Publish'leyin.

## Ortam Değişkenleri (Gerekirse)

`.env` dosyası kullanıyorsanız (flutter_dotenv paketi):
```
FIREBASE_PROJECT_ID=mobilprojesi1
FIREBASE_API_KEY=YOUR_API_KEY
```

## Test Deployment

1. Emulator/Device başlatın
2. `flutter run` çalıştırın
3. Giriş yapın (test hesabı)
4. Bildirim izinleri verin
5. Rapor oluşturun
6. Admin hesabıyla acil durum uyarısı yayınlayın
7. Notification alıp alıp almadığınız kontrol edin

## Troubleshooting

### "Repository not found" (Push başarısız)
- Git remote'u kontrol edin: `git remote -v`
- URL'yi güncelleyin: `git remote set-url origin <yeni-url>`

### APK imzalama hatası
- Keystore dosyasının yolunu kontrol edin
- Şifreleri doğrulayın

### Firebase connection error
- `google-services.json` / `GoogleService-Info.plist` yerinde olup olmadığını kontrol edin
- Firebase Console'de proje adı doğrulanmış mı?
- Internet bağlantısı var mı?

---
**Durum:** 3. gün – deployment rehberi, security rules ve test adımları eklendi.
