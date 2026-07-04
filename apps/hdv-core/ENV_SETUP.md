# Environment variables

Copy these into a local `.env.local` (which is gitignored).

```
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# Supabase service role — server-only, powers PersonaMatrix ledger/tenant writes.
# Never expose this client-side. Find it in Supabase dashboard > Project Settings > API.
SUPABASE_SERVICE_ROLE_KEY=

# HOPE companion (Anthropic)
ANTHROPIC_API_KEY=

# HOPE Cleaner (Google Drive OAuth Client ID)
NEXT_PUBLIC_GOOGLE_CLIENT_ID=

# HOPE Cleaner AI triage (Google Gemini, free tier)
GEMINI_API_KEY=
```

## HOPE Cleaner setup (`NEXT_PUBLIC_GOOGLE_CLIENT_ID`)

1. Create a project (or use an existing one) at the [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
2. Enable the **Google Drive API**.
3. Create an **OAuth 2.0 Client ID** of type "Web application".
4. Add your app's URL (e.g. `http://localhost:3000`) as an **authorized JavaScript origin**.
5. On the OAuth consent screen, add the `https://www.googleapis.com/auth/drive` scope and add yourself as a test user (this scope requires verification for public apps, but works for personal/testing use immediately).
6. Set `NEXT_PUBLIC_GOOGLE_CLIENT_ID` to the generated client ID.

## HOPE Cleaner AI triage (`GEMINI_API_KEY`)

Powers the "Why is this happening?" button on recurring-item groups, which asks an AI to
guess the automation behind a clutter pattern and suggest where to stop it.

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey) and sign in.
2. Click **Create API key** — this is free, no billing required for the default rate limits.
3. Set `GEMINI_API_KEY` to the generated key.

If unset, the button still appears but explains that AI triage needs this key configured.
