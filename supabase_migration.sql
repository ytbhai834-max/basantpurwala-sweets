-- Basantpurwala Sweets: additive customer features migration
-- BACK UP DATABASE FIRST. Run only once after reviewing current schema/policies.
create extension if not exists pgcrypto;

-- Associate new customer orders with authenticated Supabase users. Old orders remain NULL.
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists orders_user_created_idx on public.orders(user_id, created_at desc);

create table if not exists public.offers (
 id uuid primary key default gen_random_uuid(), title text not null, description text not null default '',
 discount_type text not null check(discount_type in ('percent','fixed')), discount_value numeric(10,2) not null check(discount_value>0),
 starts_at timestamptz not null, ends_at timestamptz not null, active boolean not null default true,
 created_at timestamptz not null default now(), check(ends_at>starts_at)
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade,
 title text not null, body text not null default '', is_broadcast boolean not null default false,
 created_at timestamptz not null default now(), read_at timestamptz
);
create index if not exists notifications_user_created_idx on public.notifications(user_id,created_at desc);
create table if not exists public.reviews (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 order_id uuid not null references public.orders(id) on delete cascade, rating int not null check(rating between 1 and 5),
 review_text text not null default '', approved boolean not null default false, created_at timestamptz not null default now(),
 unique(user_id,order_id)
);
create table if not exists public.loyalty_config (
 id int primary key check(id=1), points_per_100 numeric(8,2) not null default 1,
 rupees_per_point numeric(8,2) not null default 1, minimum_redeem_points int not null default 50,
 updated_at timestamptz not null default now()
);
insert into public.loyalty_config(id) values(1) on conflict(id) do nothing;
create table if not exists public.loyalty_ledger (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 order_id uuid references public.orders(id) on delete set null, points_delta int not null,
 reason text not null, created_at timestamptz not null default now(), unique(user_id,order_id,reason)
);

alter table public.offers enable row level security;
alter table public.notifications enable row level security;
alter table public.reviews enable row level security;
alter table public.loyalty_config enable row level security;
alter table public.loyalty_ledger enable row level security;

-- Public can view only currently active offers; owner can manage all offers.
drop policy if exists offers_public_active_read on public.offers;
create policy offers_public_active_read on public.offers for select to anon,authenticated
 using(active=true and now() between starts_at and ends_at);
drop policy if exists offers_owner_manage on public.offers;
create policy offers_owner_manage on public.offers for all to authenticated
 using(public.is_shop_admin()) with check(public.is_shop_admin());

-- Notifications: customers read/update only their own; admins can manage all. Broadcast rows are visible to authenticated customers.
drop policy if exists notifications_customer_read on public.notifications;
create policy notifications_customer_read on public.notifications for select to authenticated
 using(user_id=auth.uid() or is_broadcast=true or public.is_shop_admin());
drop policy if exists notifications_customer_update on public.notifications;
create policy notifications_customer_update on public.notifications for update to authenticated
 using(user_id=auth.uid() and is_broadcast=false) with check(user_id=auth.uid() and is_broadcast=false);
drop policy if exists notifications_owner_manage on public.notifications;
create policy notifications_owner_manage on public.notifications for all to authenticated
 using(public.is_shop_admin()) with check(public.is_shop_admin());

-- Customer can submit a review only for own completed order. Public sees approved reviews only.
drop policy if exists reviews_public_approved_read on public.reviews;
create policy reviews_public_approved_read on public.reviews for select to anon,authenticated using(approved=true or public.is_shop_admin() or user_id=auth.uid());
drop policy if exists reviews_customer_insert on public.reviews;
create policy reviews_customer_insert on public.reviews for insert to authenticated with check(
 user_id=auth.uid() and exists(select 1 from public.orders o where o.id=order_id and o.user_id=auth.uid() and o.status='Completed')
);
drop policy if exists reviews_owner_update on public.reviews;
create policy reviews_owner_update on public.reviews for update to authenticated using(public.is_shop_admin()) with check(public.is_shop_admin());
drop policy if exists reviews_owner_delete on public.reviews;
create policy reviews_owner_delete on public.reviews for delete to authenticated using(public.is_shop_admin());

-- Customers can read only their own loyalty ledger. Owners can inspect all.
drop policy if exists loyalty_ledger_customer_read on public.loyalty_ledger;
create policy loyalty_ledger_customer_read on public.loyalty_ledger for select to authenticated using(user_id=auth.uid() or public.is_shop_admin());
drop policy if exists loyalty_config_public_read on public.loyalty_config;
create policy loyalty_config_public_read on public.loyalty_config for select to anon,authenticated using(true);
drop policy if exists loyalty_config_owner_update on public.loyalty_config;
create policy loyalty_config_owner_update on public.loyalty_config for all to authenticated using(public.is_shop_admin()) with check(public.is_shop_admin());

-- Keep current owner order access. Customers may read only their own linked orders.
drop policy if exists orders_customer_read_own on public.orders;
create policy orders_customer_read_own on public.orders for select to authenticated using(user_id=auth.uid());
-- New authenticated checkout only: remove the legacy permissive anonymous insert policy.
drop policy if exists "customers create orders" on public.orders;
drop policy if exists orders_customer_insert_own on public.orders;
revoke insert on public.orders from anon;
create policy orders_customer_insert_own on public.orders for insert to authenticated with check(user_id=auth.uid());

grant select on public.offers to anon,authenticated;
grant insert,update,delete on public.offers to authenticated;
grant select,insert,update on public.notifications to authenticated;
grant select,insert,update,delete on public.reviews to authenticated;
grant select on public.reviews to anon;
grant select on public.loyalty_config to anon,authenticated;
grant insert,update on public.loyalty_config to authenticated;
grant select on public.loyalty_ledger to authenticated;
grant select on public.orders to authenticated;
grant insert on public.orders to authenticated;

-- Award points once when an order first becomes Completed. Cancelled order reverses earned points.
create or replace function public.bw_handle_loyalty_order()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare cfg public.loyalty_config%rowtype; pts int;
begin
 if new.status='Completed' and old.status is distinct from 'Completed' then
   select * into cfg from public.loyalty_config where id=1;
   pts:=floor((greatest(new.total,0)/100)*coalesce(cfg.points_per_100,1))::int;
   if pts>0 and new.user_id is not null then insert into public.loyalty_ledger(user_id,order_id,points_delta,reason)
     values(new.user_id,new.id,pts,'Completed order reward') on conflict(user_id,order_id,reason) do nothing; end if;
 elsif new.status='Cancelled' and old.status is distinct from 'Cancelled' then
   insert into public.loyalty_ledger(user_id,order_id,points_delta,reason)
   select user_id,order_id,-points_delta,'Cancelled order reversal' from public.loyalty_ledger
   where order_id=new.id and points_delta>0 and reason='Completed order reward'
   on conflict(user_id,order_id,reason) do nothing;
 end if;
 return new;
end; $$;
drop trigger if exists bw_order_loyalty_trigger on public.orders;
create trigger bw_order_loyalty_trigger after update of status on public.orders for each row execute function public.bw_handle_loyalty_order();

-- NOTE: Browser push requires a server-side sender (Edge Function) and VAPID private key.
-- Do not put service-role or VAPID private keys in index.html/admin.html/config.js.
