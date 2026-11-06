// ADS PROMPT GENERATOR — Gemini gateway
// The Gemini API key is read only from Supabase Edge Function secrets.
const MODEL = "gemini-3.8-flash";
const WINDOW_MS = 10 * 60 * 1000;
const MAX_REQUESTS = 12;
const buckets = new Map();

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://rifkykawitwicaksono.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function rateLimit(req: Request): boolean {
  const forwarded = req.headers.get("x-forwarded-for") || "";
  const ip = forwarded.split(",")[0].trim() || "unknown";
  const now = Date.now();
  const old = buckets.get(ip);
  if (!old || now - old.start >= WINDOW_MS) {
    buckets.set(ip, { start: now, count: 1 });
    return true;
  }
  if (old.count >= MAX_REQUESTS) return false;
  old.count++;
  return true;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!rateLimit(req)) return json({ error: "Batas sementara tercapai. Coba lagi dalam 10 menit." }, 429);

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return json({ error: "Backend belum dikonfigurasi: secret GEMINI_API_KEY belum ditambahkan di Supabase." }, 503);

  try {
    const body = await req.json();
    const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
    const images = Array.isArray(body.images) ? body.images : [];
    if (!prompt || prompt.length > 18000) return json({ error: "Prompt kosong atau terlalu panjang (maksimal 18.000 karakter)." }, 400);
    if (images.length > 4) return json({ error: "Maksimal 4 gambar per permintaan." }, 400);

    const parts: Array<Record<string, unknown>> = [{ text: prompt }];
    let totalBytes = 0;
    for (const image of images) {
      if (!image || image.mimeType !== "image/jpeg" || typeof image.data !== "string") {
        return json({ error: "Format gambar tidak valid. Unggah ulang gambar JPG/PNG." }, 400);
      }
      const approxBytes = Math.floor(image.data.length * 0.75);
      totalBytes += approxBytes;
      if (approxBytes > 4_000_000 || totalBytes > 12_000_000) {
        return json({ error: "Ukuran gambar terlalu besar. Gunakan gambar yang lebih kecil." }, 413);
      }
      parts.push({ inline_data: { mime_type: "image/jpeg", data: image.data } });
    }

    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts }],
          generationConfig: { temperature: 0.7, maxOutputTokens: 5000 },
        }),
      },
    );
    const result = await upstream.json();
    if (!upstream.ok) {
      const message = result?.error?.message || "Permintaan ke Gemini gagal.";
      const status = upstream.status === 429 ? 429 : upstream.status === 400 ? 400 : 502;
      return json({ error: message }, status);
    }
    const text = result?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text || "")
      .join("")
      .trim();
    if (!text) return json({ error: "Gemini tidak mengembalikan teks. Coba ulangi." }, 502);
    return json({ text, model: MODEL });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Terjadi kesalahan pada backend." }, 500);
  }
});
