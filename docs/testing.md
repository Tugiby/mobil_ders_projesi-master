# Test Rehberi

Uygulamanın widget testleri, unit testleri ve manuel test senaryoları.

## Widget Testleri

Mevcut widget test dosyası: [test/widget_test.dart](../test/widget_test.dart)

Çalıştırma:
```bash
flutter test test/widget_test.dart
```

Tüm testler:
```bash
flutter test
```

## Unit Testleri

Önerilen test alanları (varsa test/ içinde):
- `auth_bloc_test.dart` – AuthBloc login/register/logout
- `report_bloc_test.dart` – ReportBloc filtre/arama/durum güncelleme
- `report_repository_test.dart` – Repository mock

Örnek:
```bash
flutter test test/features/auth/bloc/auth_bloc_test.dart
```

## Manuel Test Senaryoları

### Senaryo 1: Kayıt ve Giriş
1. Uygulamayı aç → Login sayfasını gör
2. "Kayıt Ol" butonuna bas
3. Ad, e-posta, şifre, birim doldur → "Kayıt Ol" bas
4. Firebase'de kullanıcı oluşturulmalı; Firestore'da `users/{uid}` dokümanı
5. Ana sayfaya yönlendir
6. Çıkış yap
7. Giriş bilgileriyle tekrar giriş yap → başarılı olmalı

### Senaryo 2: Bildirim Oluşturma
1. Ana sayfada sağ üstte "+" butonuna bas
2. Başlık, açıklama, tür seçin
3. Konum seç (haritadan veya koordinat)
4. (Opsiyonel) fotoğraf ekle
5. "Gönder" bas
6. Rapor listesinde görüntülenmelidir (en üstte)
7. Firestore `reports` koleksiyonuna eklenmeli

### Senaryo 3: Filtreleme ve Arama
1. Ana sayfada filtre butonuna bas
2. Tür (Sağlık, Güvenlik, Çevre, Kayıp/Buluntu, Teknik) filtresini seç
3. Liste güncellenmelidir
4. "Açık olanlar" filtresini seç
5. Arama kutusuna kelime yazın → anlık filtrele
6. Takip edilen rapor filtresi (eğer rapor takip ettiyseniz gösterilmeli)

### Senaryo 4: Detay Görüntüleme ve Takip
1. Harita üzerinde pin'e bas veya liste kartına bas
2. Rapor detay sayfasını gör
3. Başlık, açıklama, tür, durum, konum, fotoğraflar gösterilmelidir
4. "Takip Et" butonuna bas → rozetleri güncelle
5. "Takipten Çık" butonuna bas → durum döneceğiz

### Senaryo 5: Admin – Durum Güncelleme
1. Admin hesabıyla giriş yap (role: 'admin' olmalı; Firestore'da `users/{uid}.role == 'admin'`)
2. Bir rapor detayına git
3. Durum chips'lerini görmeli: Açık, İnceleniyor, Çözüldü
4. "İnceleniyor" seç → Firestore rapor dokümanı güncellenir
5. Sayfayı kapat/geri dön → liste güncellenmeli
6. Raporu takip eden kullanıcılar bildirim almalı (log'a bakın)

### Senaryo 6: Admin – Acil Durum Uyarısı
1. Admin detay sayfasından sağ üst menüyü aç
2. "Acil Durum Uyarısı" seçin
3. Mesaj yazın (ör. "Kampüs kapanılmıştır")
4. "Gönder" bas
5. Firestore `alerts` koleksiyonunda doküman oluşturulmalı
6. Cloud Function tetiklenir → FCM `alerts` topic'ine push
7. Tüm cihazlarda bildirim görünmeli (foreground: snackbar, background: sistem bildirimi)

### Senaryo 7: Profil ve Ayarlar
1. Ana sayfada profil butonuna bas
2. Ad, e-posta, rol, birim bilgileri gösterilmelidir
3. Bildirim tercihleri (tür seçimi) gösterilmelidir
4. "Takip Edilen Bildirmler" sekmesinde takip edilen raporlar listelenmeli
5. "Çıkış Yap" butonuna bas → Login sayfasına git

### Senaryo 8: Harita İnteraksiyonu
1. Ana sayfada harita görünmeli
2. Yakınlaştırma/uzaklaştırma gest'leri (pinch, mouse wheel) çalışmalı
3. Pinler tür bazlı renk/ikonlarla gösterilmelidir
4. Pin'e tıklamak → kartı göster veya detay aç

## Bildirim Testleri

### FCM Bildirimi Test Etme
1. Admin hesabıyla "Acil Durum Uyarısı" gönderin
2. Cihazın/emulatörün FCM topic'e abone olduğunu kontrol edin (MessagingService logs)
3. Uygulamayı kapatıp (background) → bildirim gelmelidir
4. Bildirime tıkla → ilgili raporun detayına gitmeli

## Coverage (İsteğe Bağlı)

```bash
flutter test --coverage
```

Raporu HTML'e çevir:
```bash
# genhtml gerekli (lcov)
genhtml coverage/lcov.info -o coverage/html
# Tarayıcıda aç: coverage/html/index.html
```

---
**Durum:** 3. gün – test senaryoları ve adımları tanımlandı. Manuel testlerle başlayın, zaman kaldıkça unit test'leri yazın.
