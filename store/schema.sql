-- Digital Store foundation for ADS PROMPT GENERATOR
-- Project: pqfpdgpqvinvfooeayip
-- Run in Supabase SQL Editor. This creates separate store_* objects only.
create extension if not exists pgcrypto;

create table if not exists public.store_products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 140),
  slug text not null unique,
  category text not null default 'Produk digital',
  description text not null default '',
  price bigint not null check (price >= 0),
  image_url text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_name text not null,
  customer_email text not null,
  customer_phone text not null,
  note text not null default '',
  subtotal bigint not null check (subtotal >= 0),
  total bigint not null check (total >= 0),
  status text not null default 'pending_payment'
    check (status in ('pending_payment','paid','processing','completed','cancelled','refunded')),
  payment_reference text,
  created_at timestamptz not null default now()
);

create table if not exists public.store_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.store_orders(id) on delete cascade,
  product_id uuid not null references public.store_products(id),
  product_name text not null,
  unit_price bigint not null check (unit_price >= 0),
  quantity integer not null check (quantity between 1 and 20),
  line_total bigint not null check (line_total >= 0)
);

alter table public.store_products enable row level security;
alter table public.store_orders enable row level security;
alter table public.store_order_items enable row level security;

drop policy if exists "Public can read active store products" on public.store_products;
create policy "Public can read active store products"
on public.store_products for select to anon, authenticated
using (is_active = true);

-- Orders and order items are intentionally not directly readable/writable by anon.
revoke all on public.store_orders from anon, authenticated;
revoke all on public.store_order_items from anon, authenticated;
grant select on public.store_products to anon, authenticated;

create or replace function public.create_store_order(
  p_customer_name text,
  p_customer_email text,
  p_customer_phone text,
  p_note text,
  p_items jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order_id uuid;
  v_order_number text;
  v_subtotal bigint := 0;
  v_item jsonb;
  v_product public.store_products%rowtype;
  v_qty integer;
begin
  if length(trim(coalesce(p_customer_name,''))) < 2
     or length(trim(coalesce(p_customer_email,''))) < 5
     or length(trim(coalesce(p_customer_phone,''))) < 8 then
    raise exception 'Data pembeli tidak lengkap';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1
     or jsonb_array_length(p_items) > 20 then
    raise exception 'Keranjang tidak valid';
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item->>'quantity')::integer;
    if v_qty < 1 or v_qty > 20 then raise exception 'Jumlah produk tidak valid'; end if;
    select * into v_product from public.store_products
      where id = (v_item->>'product_id')::uuid and is_active = true;
    if not found then raise exception 'Produk tidak tersedia'; end if;
    v_subtotal := v_subtotal + (v_product.price * v_qty);
  end loop;

  v_order_number := 'DS-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.store_orders(order_number,customer_name,customer_email,customer_phone,note,subtotal,total)
  values(v_order_number,trim(p_customer_name),lower(trim(p_customer_email)),trim(p_customer_phone),coalesce(p_note,''),v_subtotal,v_subtotal)
  returning id into v_order_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_qty := (v_item->>'quantity')::integer;
    select * into v_product from public.store_products
      where id = (v_item->>'product_id')::uuid and is_active = true;
    insert into public.store_order_items(order_id,product_id,product_name,unit_price,quantity,line_total)
    values(v_order_id,v_product.id,v_product.name,v_product.price,v_qty,v_product.price*v_qty);
  end loop;

  return jsonb_build_object('id',v_order_id,'order_number',v_order_number,'status','pending_payment','total',v_subtotal);
end;
$$;

revoke all on function public.create_store_order(text,text,text,text,jsonb) from public;
grant execute on function public.create_store_order(text,text,text,text,jsonb) to anon, authenticated;

-- IMPORTANT:
-- 1) Do not mark orders paid from the browser.
-- 2) Add a payment provider Edge Function + signed webhook before accepting money.
-- 3) Keep downloadable files in a private Storage bucket. Issue short-lived signed URLs
--    only after server-side verification that the matching order is paid.
-- 4) Create an admin-only role/policy before adding product/order management UI.
