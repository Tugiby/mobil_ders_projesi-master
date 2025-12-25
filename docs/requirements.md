# Akıllı Kampüs Sağlık ve Güvenlik Bildirim Uygulaması – Gereksinimler (PDF Özeti)

Bu dosya, proje PDF’inde belirtilen teslim kriterlerini izlemek için oluşturulmuştur. Her madde tamamlandıkça işaretlenecektir.

## Roller
- [x] Kullanıcı (User) – bildirim oluşturma, listeleme, filtre/arama, harita, detay, takip
- [x] Yönetici (Admin) – bildirim yönetimi, durum güncelleme, açıklama düzenleme, sonlandırma, acil uyarı

## 1. Giriş ve Kayıt (15)
- [x] E-posta/şifre ile giriş
- [x] Başarılı giriş sonrası rol atanması (User/Admin)
- [x] Hatalı giriş mesajları
- [x] Kayıt formu: ad-soyad, e-posta, şifre, birim
- [x] Varsayılan rol: User
- [x] Şifre sıfırlama bilgi ekranı

## 2. Ana Sayfa – Bildirim Akışı (20)
- [x] Liste kartı: tür ikonu, başlık, açıklama, zaman, durum
- [x] Kronolojik sıralama (yeni→eski)
- [x] Filtreleme: tür, açık olanlar, takip edilenler, (Admin) yetki alanı
- [x] Arama: başlık+açıklama anahtar kelime

## 3. Harita Ekranı (20)
- [x] Pinler: tür bazlı renk/ikon
- [x] Yakınlaştırma/uzaklaştırma
- [x] Pin bilgi kartı: tür, başlık, oluşturulma zamanı
- [x] “Detayı Gör” ile detay ekranına geçiş

## 4. Bildirim Detay (15)
- [x] Başlık, tür, açıklama, oluşturulma zamanı
- [x] Konum (mini harita/konum metni)
- [x] Fotoğraflar (opsiyonel)
- [x] Durum yönetimi: User görüntüleme
- [x] Durum yönetimi: Admin Açık→İnceleniyor→Çözüldü
- [x] Takip et / Takipten çık

## 5. Yeni Bildirim Oluştur (15)
- [x] Tür, başlık, açıklama, konum seçimi (cihaz/harita), fotoğraf (opsiyonel)
- [x] Form doğrulaması
- [x] Başarı mesajı

## 6. Admin Paneli (10)
- [x] Tüm bildirimleri listeleme (tür, başlık, açıklama, konum, kullanıcı)
- [x] Durum güncelleme
- [x] Acil durum duyurusu yayınlama (client tarafı)
- [x] Acil durum duyurusu backend (Cloud Functions)

## 7. Profil ve Ayarlar (5)
- [x] Profil: ad-soyad, e-posta, rol, birim
- [x] Bildirim ayarları (tercihler)
- [x] Takip edilen bildirmler listesi
- [x] Çıkış

## 8. Bildirim ve Hatırlatma Sistemi (10)
- [x] Takip edilen bildirimin durum güncellemelerinde bildirim
- [x] Admin acil bildirimleri tüm kullanıcılara gönderilir (client subscribe)
- [x] Functions ile `alerts` topic push

## Git Kullanımı
- [x] Düzenli commit geçmişi (bu dosya ile görünürlük artıyor)
- [x] Adım adım ilerleme – 5 güne yayılan push planı

## Yapay Zeka Kullanımı
- [x] Kod üretmeden, danışma amaçlı destek (açıklamalar, planlama)
- [x] Büyük tek sefer commitlerden kaçınma

---
Durum: 3. gün – Deployment rehberi, test senaryoları, screenshot listesi eklendi. 4. gün – UI türkçeleştirme ve iyileştirmeler eklenecek.
