const functions = require('firebase-functions');
const admin = require('firebase-admin');

try {
  admin.initializeApp();
} catch (e) {
  // no-op if already initialized in emulator
}

// Firestore trigger: on new alert, broadcast to 'alerts' topic
exports.broadcastAlertOnCreate = functions.firestore
  .document('alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const message = data.message || 'Acil durum uyarısı';
    const reportId = data.reportId || undefined;

    const payload = {
      notification: {
        title: 'Acil Durum Uyarısı',
        body: message,
      },
      data: {
        type: 'alert',
        ...(reportId ? { reportId: String(reportId) } : {}),
      },
      topic: 'alerts',
    };

    try {
      const resp = await admin.messaging().send(payload);
      console.log('Alert broadcast sent:', resp);
    } catch (err) {
      console.error('Alert broadcast failed:', err);
    }
  });
