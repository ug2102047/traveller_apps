const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin app. When deployed in Firebase, this uses the project
// credentials automatically.
admin.initializeApp();

const db = admin.firestore();

// HTTP-triggered one-off backfill to populate `reviews/{id}.user` for
// documents where 'user' is missing or equals the raw uid.
// Usage: deploy and then call the function URL once from your browser or curl.
exports.backfillReviewUser = functions.https.onRequest(async (req, res) => {
  try {
    const snapshot = await db.collection('reviews').get();
    let updated = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const uid = data.userId;
      // Skip docs which already have a user field that doesn't equal the uid
      if (!uid) continue;
      if (data.user && data.user !== uid) continue;

      try {
        const userRecord = await admin.auth().getUser(uid);
        // Prefer email for display, then displayName, then uid.
        const name = userRecord.email || userRecord.displayName || uid;
        await doc.ref.update({ user: name });
        updated++;
      } catch (err) {
        console.error(`Failed to resolve user for review ${doc.id}:`, err.message || err);
        // continue with other docs
      }
    }

    res.status(200).send(`Backfill complete. Updated ${updated} documents.`);
  } catch (err) {
    console.error('Backfill error:', err);
    res.status(500).send('Backfill failed: ' + (err.message || err));
  }
});

// Note: tourPlanner function removed.

// QA handler (scaffolded in qaHandler.js)
try {
  const qaHandler = require('./qaHandler');
  // qaHandler exports a function object 'qaHandler' already defined as onRequest
  if (qaHandler && qaHandler.qaHandler) {
    exports.qaHandler = functions.https.onRequest((req, res) => qaHandler.qaHandler(req, res));
  }
} catch (err) {
  console.warn('qaHandler module not found or failed to load:', err && err.message);
}

// verifyEmail handler removed — email verification uses Firebase built-in flow now.
