# YouTube Music OAuth and InnerTube POC

## Purpose

This POC answers one specific question: can an OAuth access token issued to the
Android app perform authenticated YouTube Music InnerTube operations?

Google authentication alone is not considered a successful connection. The app
enables Continue only after both of these non-destructive InnerTube calls return
successful, structurally valid authenticated responses:

1. `account/account_menu`
2. `browse` with `FEmusic_liked_playlists`

The POC also includes an opt-in debug capability check for `playlist/create`
and `browse/edit_playlist`. It never runs automatically.

## Authentication strategy

- `google_sign_in` uses the supported Android Google authentication UI.
- The app requests `https://www.googleapis.com/auth/youtube`.
- The Google SDK manages its authentication session and token cache.
- The application does not persist, print, or expose access tokens.
- `flutter_secure_storage` stores only the safe account identifier and the
  timestamps of the last successful InnerTube validation.
- Restored sessions are revalidated before the connection becomes usable.

InnerTube is an unofficial API. A valid OAuth token may still be rejected by
YouTube Music. That outcome is a POC result, not a reason to extract browser
cookies or weaken browser security.

## Google Cloud setup for Android

1. Open Google Cloud Console and create or select a project.
2. Open **APIs & Services > Library** and enable **YouTube Data API v3**.
3. Open **Google Auth Platform** and configure the OAuth consent screen.
4. Add the Google account used for this POC as a test user while the consent
   screen is in Testing status.
5. Create an **Android OAuth client** with:
   - Package name: `com.example.transfer_aplicationn`
   - SHA-1: the fingerprint of the key that signs the installed build.
6. For the local debug key on Windows, obtain SHA-1 with:

   ```powershell
   keytool -list -v -alias androiddebugkey `
     -keystore "$env:USERPROFILE\.android\debug.keystore" `
     -storepass android -keypass android
   ```

7. Create a **Web application OAuth client** in the same Google Cloud project.
   Copy its client ID. The Android `google_sign_in` implementation requires
   this value as `serverClientId` when `google-services.json` is not used.
8. Do not copy or embed the Web client secret. This client-side POC does not
   use a client secret.

The current package name is a development identifier. Register the production
application ID and its release/Play App Signing SHA-1 separately before release.

## Run the read-validation POC

```powershell
flutter run --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<WEB_CLIENT_ID>
```

Replace `<WEB_CLIENT_ID>` with the complete **Web application** client ID,
including its `.apps.googleusercontent.com` suffix, not the Android client ID.
Add `-d <ANDROID_DEVICE_ID>` if you need to select an Android device. Stop the
running app and rerun this command after changing the define; hot reload does
not update compile-time configuration.

The app passes this define to `GoogleSignIn.initialize(serverClientId: ...)`
and awaits initialization before authentication. An absent or blank value
prevents sign-in and produces a clear configuration failure. Client/provider
configuration errors use the same safe message. Check the Web client ID and
the registered Android package/signing SHA-1 if it appears with a configured
value. Never include credentials or raw SDK exceptions in logs.

Manual checklist:

1. Launch the app.
2. Import at least one Exportify CSV playlist.
3. Tap Continue.
4. Tap **Connect YouTube Music**.
5. Select the intended Google account and approve YouTube access.
6. Return to the app if the system authentication UI changed applications.
7. Observe **Connecting...**, then **Verifying...**.
8. Confirm **Connected** appears only after validation.
9. Confirm Continue is enabled only in that state.
10. Tap Continue and confirm navigation to the Home placeholder.

If validation fails, capture only the safe HTTP status and failure category
from diagnostics. Never copy tokens, cookies, or Authorization headers.

## Run the development write-capability check

This check is available only in a debug build and only when explicitly enabled:

```powershell
flutter run -d <ANDROID_DEVICE_ID> `
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com `
  --dart-define=ENABLE_YOUTUBE_WRITE_POC=true
```

After a validated connection, tap **Run development write check**. It creates
one private playlist named like:

```text
Music Transfer POC - TEMPORARY - <timestamp>
```

To also test adding one known video, provide its YouTube video ID:

```powershell
flutter run -d <ANDROID_DEVICE_ID> `
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com `
  --dart-define=ENABLE_YOUTUBE_WRITE_POC=true `
  --dart-define=YOUTUBE_POC_VIDEO_ID=<VIDEO_ID>
```

The POC does not modify existing playlists and does not automatically delete
the temporary playlist. Remove it manually after confirming the result.

## Safe diagnostics

Allowed diagnostic events contain only step names and HTTP status codes:

- `OAuth step started`
- `OAuth completed`
- `InnerTube validation request completed (HTTP ...)`
- `Authenticated InnerTube library request succeeded (HTTP 200)`
- `Create-playlist capability succeeded (HTTP 200)`

Response bodies, OAuth tokens, cookies, authorization headers, and client
secrets are never logged.

## Current real capability result

| Capability | Result |
| --- | --- |
| OAuth login | NOT TESTED - requires configured Google OAuth clients and manual login |
| Authenticated InnerTube read | NOT TESTED - runs only after manual OAuth login |
| Create playlist | NOT TESTED - development check is opt-in |
| Add playlist item | NOT TESTED - requires an explicit test video ID |

Do not change any result to PASS without running it against a real account and
recording the safe HTTP status evidence.
