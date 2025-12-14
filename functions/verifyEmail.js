const fetch = require('node-fetch');
const functions = require('firebase-functions');

// This handler receives an `oobCode` (one-time code) from the email
// verification link. It calls the Firebase Identity Toolkit REST API
// to apply the code and then responds with a small HTML page that
// informs the user and redirects them to the app homepage.

// Requires the Firebase Web API key (not secret) to be available as
// process.env.FIREBASE_WEB_API_KEY or functions.config().auth.api_key
function getApiKey() {
  if (process.env.FIREBASE_WEB_API_KEY) return process.env.FIREBASE_WEB_API_KEY;
  try {
    const conf = functions.config();
    if (conf && conf.auth && conf.auth.api_key) return conf.auth.api_key;
  } catch (e) {
    // ignore
  }
  return null;
}

module.exports = async function verifyEmailHandler(req, res) {
  const oobCode = req.query.oobCode || req.body && req.body.oobCode;
  const continueUrl = req.query.continue || `https://travellerapp2025.firebaseapp.com/?emailVerified=1`;

  if (!oobCode) {
    res.status(400).send('<h2>Missing code</h2><p>No verification code provided.</p>');
    return;
  }

  const apiKey = getApiKey();
  if (!apiKey) {
    res.status(500).send('<h2>Server misconfigured</h2><p>Missing FIREBASE_WEB_API_KEY. Set it in functions config or environment.</p>');
    return;
  }

  try {
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${apiKey}`;
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ oobCode }),
    });
    const data = await resp.json();

    if (!resp.ok) {
      const message = (data && data.error && data.error.message) || JSON.stringify(data);
      const html = `
        <html><head><meta http-equiv="refresh" content="6;url=${continueUrl}" /></head>
        <body>
          <h2>Verification failed</h2>
          <p>${message}</p>
          <p>Redirecting you back shortly. If not, <a href="${continueUrl}">click here</a>.</p>
        </body></html>`;
      res.status(400).send(html);
      return;
    }

    // Success — the REST API applied the action code and verified the email.
    const html = `
      <html>
        <head>
          <meta http-equiv="refresh" content="4;url=${continueUrl}" />
          <style>body{font-family:Arial,Helvetica,sans-serif;padding:24px;color:#333}</style>
        </head>
        <body>
          <h2>Email Verified</h2>
          <p>Your email address has been verified successfully.</p>
          <p>Redirecting to the app homepage. If you are not redirected, <a href="${continueUrl}">click here</a>.</p>
        </body>
      </html>`;

    res.status(200).send(html);
  } catch (err) {
    console.error('verifyEmailHandler error:', err && err.stack || err);
    res.status(500).send('<h2>Server error</h2><p>See logs for details.</p>');
  }
};
