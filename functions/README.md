Backfill `reviews.user` Cloud Function

This folder contains a small Cloud Function to backfill the `user` field
in `reviews` documents using the Firebase Admin SDK.

Files:

- `index.js` – HTTP function `backfillReviewUser` that reads all reviews
  and updates `user` using the Auth record for `userId`.
- `package.json` – Node 18 runtime and required dependencies.

How to deploy (locally):

1. Install Firebase CLI and login:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. Initialize functions if you haven't already (only if functions/ wasn't
   created by `firebase init` earlier). From the project root run:

   ```bash
   firebase init functions
   ```

   If prompted, choose the existing `functions` folder and select Node 18.

3. Install dependencies and deploy the function:

   ```bash
   cd functions
   npm install
   firebase deploy --only functions:backfillReviewUser
   ```

4. Invoke the function once (the deploy output includes a URL), or call
   it from the console or with `curl`:
   ```bash
   curl -X GET "https://us-central1-YOUR_PROJECT.cloudfunctions.net/backfillReviewUser"
   ```

Notes:

- Running this requires that the Firebase project contains the user
  accounts (Auth) referenced by `reviews.userId` and that you have
  permission to call `admin.auth().getUser(uid)`.
- This operation is one-off. After successful run you can remove the
  function or keep it for future maintenance.

---

## QA Cloud Function (AI proxy)

This repository also includes a scaffolded Cloud Function `qaHandler` intended
to proxy app questions to the OpenAI (Chat Completions) API so the client
never holds the API key.

Quick deploy steps (summary):

1. Install dependencies:

```powershell
cd "e:/5th semester/Software Development Project - (CCE-314)/Flutter Project/traveller/functions"
npm install
```

2. Set the OpenAI key in functions config (server-side, secure):

```powershell
# replace YOUR_OPENAI_KEY with your real key
firebase functions:config:set openai.key="YOUR_OPENAI_KEY"
```

3. Deploy the `qaHandler` function:

```powershell
cd "e:/5th semester/Software Development Project - (CCE-314)/Flutter Project/traveller"
firebase deploy --only functions:qaHandler
```

4. After deploy, note the Function URL printed by the CLI (e.g.
   `https://us-central1-YOUR_PROJECT.cloudfunctions.net/qaHandler`).

Client: run Flutter with the function URL supplied via `--dart-define`:

```powershell
flutter run -d chrome --dart-define=QA_BACKEND_URL="https://us-central1-YOUR_PROJECT.cloudfunctions.net/qaHandler"
```

Or edit `lib/services/qa_service.dart` and replace the placeholder.

Security notes: use `firebase functions:config:set` or Secret Manager; do
not commit API keys into source control.

If you paste the deployed function URL here, I can update `lib/services/qa_service.dart`
for you (or you can run the `flutter run` command above to test immediately).
