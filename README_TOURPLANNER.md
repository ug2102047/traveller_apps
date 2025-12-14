Tour Planner (Option B) — Setup & Deployment

This document explains how to deploy a simple Cloud Function backend and how to connect the Flutter client `TourPlannerService` to it.

1. Enable APIs & create project

- In Google Cloud Console enable: Places API, Maps JavaScript API (if you plan maps), and Billing must be enabled.

2. Prepare Cloud Functions (recommended: use Firebase Functions)

- This repo contains `functions/tourPlanner.js` which exports a simple handler function.
- You can integrate it into `functions/index.js` by importing and exposing it as a function.

Example (functions/index.js):

const functions = require('firebase-functions');
const tourPlannerHandler = require('./tourPlanner');

exports.tourPlanner = functions.https.onRequest((req, res) => tourPlannerHandler(req, res));

3. Set your API key securely

- Do NOT put the Google API key into client code.
- For Firebase Functions you can set config: `firebase functions:config:set google.key="YOUR_KEY_HERE"`
- In code you can access `functions.config().google.key` or set an env var `GOOGLE_API_KEY` on deployment.

4. Deploy

- From the `functions/` directory run:
  npm install
  firebase deploy --only functions:tourPlanner

- Or use `gcloud functions deploy tourPlanner --runtime nodejs18 --trigger-http --region us-central1 --set-env-vars GOOGLE_API_KEY=YOUR_KEY`

5. Connect Flutter client

- In `lib/services/tour_planner_service.dart` set `_backendUrl` to the deployed function URL, e.g.
  https://us-central1-YOUR_PROJECT.cloudfunctions.net/tourPlanner

6. Run the app

- `flutter pub get` (we added `http` dependency)
- `flutter run -d chrome`

7. Notes

- Monitor billing: Places API calls incur charges. Use caching and limit requests per user.
- Add API key restrictions and server-side rate-limiting for production.
- You can translate returned place names/descriptions to Bangla on the client if desired.

If you want, I can:

- Add the `tourPlanner` export into `functions/index.js` for you (requires editing the file).
- Deploy the function (I cannot deploy from here, but I can provide exact commands and code).
- Improve heuristics or translate results to Bangla automatically on the server.
