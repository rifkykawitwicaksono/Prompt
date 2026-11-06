# ADS PROMPT GENERATOR — Supabase AI backend

This repository uses a Supabase Edge Function as a server-side gateway to Gemini. The Gemini API key is never placed in the public website.

## Project
- Supabase URL: https://pqfpdgpqvinvfooeayip.supabase.co
- Project ref: `pqfpdgpqvinvfooeayip`
- Edge Function name: `ai-gateway`
- Model: `gemini-3.8-flash`

## A. Add the Gemini secret
1. Open [Google AI Studio API keys](https://aistudio.google.com/app/apikey) and create an API key.
2. Open [Supabase Edge Function Secrets](https://supabase.com/dashboard/project/pqfpdgpqvinvfooeayip/settings/functions).
3. Add a secret:
   - Name: `GEMINI_API_KEY`
   - Value: paste the Gemini API key you just created
4. Save. Never send this key in chat or commit it to GitHub.

## B. Deploy the function without installing anything
1. Open [Supabase Edge Functions](https://supabase.com/dashboard/project/pqfpdgpqvinvfooeayip/functions).
2. Click **Deploy a new function** → **Via Editor**.
3. Set the function name to `ai-gateway`.
4. Replace the editor's sample code with the complete code from [supabase/functions/ai-gateway/index.ts](https://github.com/rifkykawitwicaksono/Prompt/blob/main/supabase/functions/ai-gateway/index.ts).
5. Click **Deploy function** and wait for the success message.

Alternative for a computer with Supabase CLI installed:
```bash
supabase login
supabase link --project-ref pqfpdgpqvinvfooeayip
supabase functions deploy ai-gateway
```

## C. Test
Open the function details in Supabase and use **Test** with:
- Method: `POST`
- Header: `Content-Type: application/json`
- Header: `apikey: <your Supabase publishable key>`
- Body:
```json
{"prompt":"Return exactly this text: BACKEND OK","images":[]}
```
A successful response contains a `text` field.

## Limits and cautions
- The function rejects prompts above 18,000 characters and more than four images.
- It has a best-effort in-memory throttle of 12 requests per 10 minutes per running instance. This is not a durable quota or a substitute for user authentication; instance restarts and multiple edge instances can reset/spread this limit.
- Gemini free-tier access and quotas are limited and may change. Google states that content sent through its free tier may be used to improve its products. Do not send confidential or sensitive material.
- This gateway generates text and analyzes uploaded images. It does not generate finished video, audio, or music. Those require separate providers and may incur costs.
