# Ekran Görüntüleri

Bu klasör, uygulamanın çeşitli ekranlarının screenshot'larını içerir.

## Ekran Listesi (Tüm Platformlar)

### 1. Giriş Ekranı (Login)
- Dosya: `1_login.png`
- Açıklama: E-posta/şifre alanları, giriş butonu, kayıt/şifre sıfırlama geçişleri

### 2. Kayıt Ekranı (Register)
- Dosya: `2_register.png`
- Açıklama: Ad-soyad, e-posta, şifre, birim alanları

### 3. Şifre Sıfırlama (Forgot Password)
- Dosya: `3_forgot_password.png`
- Açıklama: E-posta alanı, bilgi mesajı

### 4. Ana Sayfa – Liste Görünümü (Home – List View)
- Dosya: `4_home_list.png`
- Açıklama: Bildirim kartları, filtre butonları, arama alanı

### 5. Ana Sayfa – Harita Görünümü (Home – Map View)
- Dosya: `5_home_map.png`
- Açıklama: Harita, pinler, filter chips, pin bilgi kartı

### 6. Bildirim Detay – User Görünümü (Report Detail – User)
- Dosya: `6_detail_user.png`
- Açıklama: Başlık, tür, durum, açıklama, konum, fotoğraflar, takip et butonu

### 7. Bildirim Detay – Admin Görünümü (Report Detail – Admin)
- Dosya: `7_detail_admin.png`
- Açıklama: Durum yönetimi (chips), açıklama düzenleme menüsü, acil uyarı butonu

### 8. Yeni Bildirim Oluştur (Create Report)
- Dosya: `8_create_report.png`
- Açıklama: Form (başlık, açıklama, tür, konum, fotoğraf), harita seçici

### 9. Profil ve Ayarlar (Profile)
- Dosya: `9_profile.png`
- Açıklama: Kullanıcı bilgileri, bildirim tercihleri, takip edilen bildirmler, çıkış

### 10. Admin Kullanıcı Yönetimi (Admin – User Management)
- Dosya: `10_user_management.png`
- Açıklama: Kullanıcı listesi, rol değişim düğmeleri

## Screenshot Nasıl Alınır?

### Android (Emulator/Device)
```bash
# Adb ile
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/

# Android Studio
Device File Explorer → /sdcard/ → screenshot.png sağ tıkla → Save As
```

### iOS (Simulator)
```bash
# Cmd + S (Simulator menüsü → File → Save Screenshot)
# Veya terminal
xcrun simctl io booted screenshot screenshots/ios_screenshot.png
```

### Web (Chrome DevTools)
```
Ctrl+Shift+P (Mac: Cmd+Shift+P) → "Capture screenshot" veya F12 → Device Toolbar
```

## Dosya Adlandırması

Format: `N_screen_name.png` (N: sıra, açıklayıcı ad)

Örnek:
- `1_login.png`
- `4_home_list.png`
- `7_detail_admin.png`

## Boyut Önerileri

- Android: 1080x2340 (Pixel 4a), 1440x3120 (Pixel 5)
- iOS: 1125x2436 (iPhone 12), 1170x2532 (iPhone 13)
- Web: 1280x720 minimum

---
**Durum:** 3. gün – ekran listesi ve screenshot alım kılavuzu hazırlandı. Her ekranın görüntüsünü bu klasöre ekleyin.
