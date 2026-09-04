# Music Transfer

A Flutter proof of concept for importing Spotify playlists exported as CSV and
validating access to YouTube Music before continuing to the transfer workflow.

## Current flow

- Import one or more Exportify CSV files.
- Review imported playlist and track totals locally.
- Authenticate with Google and validate authenticated YouTube Music reads.
- Continue to the Home placeholder with the imported playlist data intact.
- Optionally run the explicitly enabled debug-only write capability check.

The actual playlist matching and transfer engine are intentionally outside the
current scope.

## Development

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Google OAuth setup and the safe InnerTube POC procedure are documented in
[docs/youtube_music_oauth_poc.md](docs/youtube_music_oauth_poc.md). Real-account
OAuth and InnerTube capability results must not be marked as successful until
the documented manual validation has been performed.
