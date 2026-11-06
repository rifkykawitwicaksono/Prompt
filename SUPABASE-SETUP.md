# ADS PROMPT GENERATOR — Supabase AI backend

This repository uses a Supabase Edge Function as a server-side gateway to the Gemini API. The Gemini key is never placed in the public website.

## Project
- Supabase URL: https://pqfpdgpqvinvfooeayip.supabase.co
- Edge Function: `ai-gateway`
- Model: `gemini-3.8-flash`

## One-time setup in Supabase
1. Open the project dashboard: https://supabase.com/dashboard/project/pqfpdgpqvinvfooeayip
2. Open **Edge Functions → Secrets** (or **Project Settings → Edge Functions → Secrets**).
3. Create a Gemini API key in Google AI Studio: https://aistudio.google.com/app/apikey
4. Add a secret with name `GEMINI_API_KEY` and value set to your Gemini API key. Save it. Never commit this key to GitHub or put it in the website.
5. Free-tier limits and model access are controlled by Google and can change. Google may process free-tier prompts and images under its free-tier data terms; do not send confidential or sensitive material.

## Deploy the function
The source is in `supabase/functions/ai-gateway/index.ts`. It must be deployed to the project above. From a computer with Supabase CLI installed, run:

```bash
supabase login
supabase link --project-ref pqfpdgpqvinvfooeayip
supabase functions deploy ai-gateway
```

The function is configured with JWT verification disabled because the static GitHub Pages client calls it with the project's publishable key. The publishable key is intended for browser use; the Gemini key remains server-side.

## Limits and cautions
- The function rejects prompts above 18,000 characters and more than four images.
- It includes a best-effort per-IP in-memory throttle (12 calls per 10 minutes per running instance). This is not a durable quota or a substitute for user authentication; instance restarts and multiple edge instances can reset/spread this limit.
- Gemini free-tier quotas are limited and may change. Image/video generation is not included in this text-generation gateway.
