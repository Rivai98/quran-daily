# Google sign-in: owner setup steps

You do these steps once. Nothing secret goes into the app or the repo.

## 1. Google Cloud Console (https://console.cloud.google.com)

1. Create or pick a project, e.g. "Quran Daily".
2. **APIs & Services → OAuth consent screen**: User type **External**, app name
   "ورد يومي / Quran Daily", support email, then save. Add yourself as a test user
   while the app is in Testing mode.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**, three times:

| Type | Fields |
|------|--------|
| **Web application** | Name: `supabase-web`. Authorized redirect URI: `https://zwkvijapswwutwozbvgy.supabase.co/auth/v1/callback`. Keep the **Client ID** and **Client secret**. |
| **Android** | Package name: `com.example.quran_daily`. SHA-1 (debug key on this PC): `BD:47:63:FA:0C:1E:BA:68:25:AE:F9:16:7F:EC:32:32:97:5E:02:87` |
| **iOS** (optional until we build for iPhone) | Bundle ID: `com.example.quranDaily` |

For the release build, add a second Android client later with the release key's SHA-1.

## 2. Supabase dashboard (project zwkvijapswwutwozbvgy)

**Authentication → Sign In / Providers → Google**:
- Enable it.
- Client IDs: paste the **Web** client ID, then a comma, then the **Android** client ID (and the iOS one if you made it).
- Client Secret: paste the **Web** client secret. This is the only place it goes.
- Turn on **Skip nonce check** (needed for the native Android picker).
- Save.

## 3. The app's `.env` (local only, gitignored)

Add a line with the **Web** client ID. It's a public identifier, not a secret:

```
GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

Then tell Claude it's done, and the phone test (T012) runs.
