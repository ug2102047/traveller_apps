const functions = require('firebase-functions');
const fetch = require('node-fetch');

// NOTE: This is a scaffold. To make this work you must set the environment
// variable OPENAI_API_KEY in your Cloud Functions environment (or use
// Secret Manager) and deploy the function. This function proxies client
// requests to the OpenAI Chat Completions endpoint.

exports.qaHandler = functions.https.onRequest(async (req, res) => {
  // Handle CORS preflight
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  try {
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');
    const body = req.body || {};
    const question = body.question || '';
    if (!question) return res.status(400).send({ error: 'question required' });

    console.log('qaHandler received question length:', question.length);

    // Prefer functions config (set via `firebase functions:config:set openai.key="..."`)
    let apiKey = (functions.config && functions.config().openai && functions.config().openai.key) || process.env.OPENAI_API_KEY;
    if (!apiKey) {
      return res.status(500).send({ error: 'Server misconfigured: missing OpenAI API key' });
    }

    const payload = {
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: question }],
      max_tokens: 600,
    };

    let r;
    try {
      r = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify(payload),
      });
    } catch (fetchErr) {
      console.error('Network error calling OpenAI:', fetchErr && fetchErr.message ? fetchErr.message : fetchErr);
      return res.status(502).send({ error: 'Network error when calling OpenAI', details: String(fetchErr) });
    }

    if (!r.ok) {
      const txt = await r.text();
      console.error('OpenAI upstream error', { status: r.status, body: txt });
      // Include the upstream status and text in the returned error to aid local debugging
      return res.status(502).send({ error: `Upstream error (status ${r.status}): ${txt}`, details: txt });
    }

    const data = await r.json();
    // Extract assistant message
    const msg = data.choices && data.choices[0] && data.choices[0].message
      ? data.choices[0].message.content
      : '';

    return res.json({ answer: msg });
  } catch (err) {
    console.error('qaHandler unexpected error:', err && err.stack ? err.stack : err);
    // Include message/stack in dev environment to aid debugging. Do not expose secrets in production.
    return res.status(500).send({ error: err && err.message ? err.message : String(err), stack: err && err.stack ? err.stack : undefined });
  }
});
