# Acil Durum Uyarı Sistemi

Bu dokümantasyon, admin tarafından yayınlanan acil durum uyarılarının tüm kullanıcılara nasıl iletildiğini açıklar.

## Mimari Akış

1. **Client (Admin):** [ReportDetailPage](../lib/features/reports/presentation/pages/report_detail_page.dart)'de "Acil Durum Uyarısı" menüsünden mesaj girip gönderir.
2. **Firestore:** `alerts` koleksiyonuna yeni belge eklenir:
   ```json
   {
     "message": "Uyarı metni",
     "reportId": "raporID",
     "createdAt": Timestamp,
     "authorUid": "adminUID"
   }
   ```
3. **Cloud Functions:** [functions/index.js](../functions/index.js) içindeki `onAlertCreated` trigger tetiklenir; FCM ile `alerts` topic'ine push notification gönderilir.
4. **Client (Tüm Kullanıcılar):** [MessagingService](../lib/services/messaging_service.dart) `alerts` konusuna abone olduğu için bildirim alır; foreground'da local notification + snackbar, background/terminated'da sistem bildirimi gösterilir.

## Cloud Functions Deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

### Gereksinimler
- Firebase CLI yüklü (`npm install -g firebase-tools`)
- `firebase login` ile giriş yapılmış
- Firebase proje ID: mobilprojesi1

### Test
1. Admin hesabıyla giriş yapın.
2. Bir rapor detayına gidin, sağ üst menüden "Acil Durum Uyarısı" seçin.
3. Mesaj yazıp gönderin → `alerts` koleksiyonunda belge oluşur.
4. Cloud Function tetiklenir → tüm cihazlarda bildirim gelir.

## Güvenlik Notları

Firestore Security Rules önerisi (opsiyonel; production için):
```javascript
match /alerts/{alertId} {
  allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
  allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
  allow update, delete: if false;
}
```

Şu anda rule'lar basitleştirilmiş haldedir; admin doğrulaması client tarafında yapılır. Üretim ortamında mutlaka Firestore kurallarını güncelleyin.

---
**Durum:** 2. gün – Cloud Functions backend eklendi; acil uyarı sistemi tam çalışır halde.
