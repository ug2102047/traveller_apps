## Email verification Cloud Function

What this function does

- `verifyEmail` (HTTP) accepts an `oobCode` (the Firebase one-time action code) and calls
  the Identity Toolkit REST API to apply the code and mark the email as verified. It
  then returns a small HTML page confirming success and redirects to the app homepage.

How to configure locally (Functions emulator)

1. The function needs your project's Web API key (the same API key used by the web app).
   Provide it as an environment variable when running the emulator or in `functions/.runtimeconfig.json`.

   Example `.runtimeconfig.json` (functions/ folder):

   {
   "auth": {
   "api_key": "YOUR_FIREBASE_WEB_API_KEY"
   }
   }

   Or set OS env var before launching the emulator (PowerShell):

   $env:FIREBASE_WEB_API_KEY = 'YOUR_FIREBASE_WEB_API_KEY'
   npx firebase emulators:start --only functions

2. When testing the sign-up flow the app will send verification links pointing to the
   `verifyEmail` endpoint. If you're running the Functions emulator locally the link
   may need to be adjusted to point to the emulator host. For quick testing it's okay
   to keep the deployed function URL if you have the function deployed; otherwise use
   the emulator URL printed by the emulator when it starts.

Security note

- The web API key is not a secret but should not be published carelessly in public
  repositories. Do NOT commit private API keys into source control.

Next steps / production

- Deploy the function to your project (requires Blaze billing for some features).
- Ensure your app homepage URL (used in the function's redirect) is correct for production.
