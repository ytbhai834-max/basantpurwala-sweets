-- Basantpurwala Sweets secure database starter
create extension if not exists pgcrypto;

create table if not exists public.shop_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'mithai',
  description text not null default '',
  image_url text not null default '',
  price numeric(10,2) not null default 0 check (price >= 0),
  available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_phone text not null,
  order_type text not null check (order_type in ('Pickup','Delivery')),
  delivery_address text not null default '',
  payment_method text not null check (payment_method in ('Cash','UPI QR Code')),
  customer_note text not null default '',
  items jsonb not null,
  subtotal numeric(10,2) not null check (subtotal >= 0),
  delivery_charge numeric(10,2) not null default 0 check (delivery_charge >= 0),
  total numeric(10,2) not null check (total >= 0),
  status text not null default 'New' check (status in ('New','Accepted','Preparing','Ready','Completed','Cancelled')),
  payment_status text not null default 'Pending' check (payment_status in ('Pending','Paid','Failed')),
  created_at timestamptz not null default now()
);

alter table public.shop_admins enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

create or replace function public.is_shop_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.shop_admins a where a.user_id = auth.uid());
$$;

revoke all on function public.is_shop_admin() from public;
grant execute on function public.is_shop_admin() to authenticated, anon;

-- Everyone can read products that are available. Only authenticated owner can edit.
drop policy if exists "public reads available products" on public.products;
create policy "public reads available products" on public.products
for select to anon, authenticated using (available = true or public.is_shop_admin());

drop policy if exists "owner inserts products" on public.products;
create policy "owner inserts products" on public.products
for insert to authenticated with check (public.is_shop_admin());

drop policy if exists "owner updates products" on public.products;
create policy "owner updates products" on public.products
for update to authenticated using (public.is_shop_admin()) with check (public.is_shop_admin());

drop policy if exists "owner deletes products" on public.products;
create policy "owner deletes products" on public.products
for delete to authenticated using (public.is_shop_admin());

-- Customers can submit orders. Only owner can read/update orders.
drop policy if exists "customers create orders" on public.orders;
create policy "customers create orders" on public.orders
for insert to anon, authenticated with check (true);

drop policy if exists "owner reads orders" on public.orders;
create policy "owner reads orders" on public.orders
for select to authenticated using (public.is_shop_admin());

drop policy if exists "owner updates orders" on public.orders;
create policy "owner updates orders" on public.orders
for update to authenticated using (public.is_shop_admin()) with check (public.is_shop_admin());

-- Grant only necessary operations; RLS still controls which rows/actions are allowed.
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update on public.orders to authenticated;
grant select on public.shop_admins to authenticated;
