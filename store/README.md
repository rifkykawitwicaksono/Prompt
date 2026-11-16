# Digital Store — foundation

This storefront is added in a separate `/store/` directory. The existing root `index.html` for ADS PROMPT GENERATOR is intentionally untouched.

## Current files
- `index.html`: modern responsive storefront, product catalogue, category/search, cart, checkout form.
- `schema.sql`: separate `store_*` tables and secure order-creation RPC.

## Publish
GitHub Pages project URL will be:
`https://rifkykawitwicaksono.github.io/Prompt/store/`

## Supabase setup
1. Open the existing project: https://supabase.com/dashboard/project/pqfpdgpqvinvfooeayip
2. Open SQL Editor.
3. Run `schema.sql`.
4. Add products to `public.store_products` with `is_active=false` first; verify descriptions, price and image, then set `is_active=true`.
5. Update `STORE_NAME` in `index.html` after choosing the final brand.

## Important payment status
This is a storefront and order-creation foundation, not a live payment integration yet. Checkout creates an order with `pending_payment`; it does not collect money and must not be treated as paid. Before launch, configure a payment gateway on a Supabase Edge Function, validate its signed webhook, then mark the order paid server-side. Never put payment secret keys or Supabase service-role keys in browser code.

## Digital delivery
Keep downloadable assets in a private Supabase Storage bucket. Generate short-lived signed download URLs only after server-side checks confirm a paid order. Do not put private download links in the public product table.

## Existing generator
The existing root `index.html` remains unchanged. The store lives at `/store/`, so the existing generator URL and its working functions are preserved.
