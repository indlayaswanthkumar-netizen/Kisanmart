-- KisanMart Phase 1 foundation. Apply only to a KisanMart Supabase project.
-- Authenticated clients never receive privileged role, price, stock, payment,
-- moderation, or order-total write access through this migration.

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

do $$ begin
  create type public.app_role as enum ('farmer', 'seller', 'admin');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.seller_status as enum ('pending', 'approved', 'rejected', 'suspended');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.product_status as enum ('draft', 'pending_review', 'published', 'rejected', 'archived');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.order_status as enum ('awaiting_payment', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'return_requested', 'returned', 'refunded');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.payment_status as enum ('pending', 'authorized', 'paid', 'failed', 'partially_refunded', 'refunded');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.shipment_status as enum ('pending', 'packed', 'shipped', 'delivered', 'cancelled');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.review_status as enum ('pending', 'published', 'rejected');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.content_status as enum ('draft', 'published', 'archived');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.coupon_discount_type as enum ('percentage', 'fixed_amount');
exception when duplicate_object then null;
end $$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  locale text not null default 'en' check (locale in ('en', 'te', 'hi')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null default 'farmer',
  granted_by uuid references public.profiles(id) on delete set null,
  granted_at timestamptz not null default now(),
  unique (user_id, role)
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  recipient_name text not null,
  phone text not null,
  address_line_1 text not null,
  address_line_2 text,
  locality text,
  city text not null,
  state text not null,
  postal_code text not null check (postal_code ~ '^[0-9]{6}$'),
  country_code text not null default 'IN' check (country_code = 'IN'),
  delivery_instructions text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index addresses_one_default_per_user
  on public.addresses(user_id) where is_default;
create index addresses_user_id_idx on public.addresses(user_id);

create table public.sellers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete restrict,
  business_name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  support_email text,
  support_phone text,
  state text,
  approval_status public.seller_status not null default 'pending',
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  moderation_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index sellers_approval_status_idx on public.sellers(approval_status);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index categories_parent_sort_idx on public.categories(parent_id, sort_order);

create table public.crops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  scientific_name text,
  description text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.crop_stages (
  id uuid primary key default gen_random_uuid(),
  crop_id uuid not null references public.crops(id) on delete cascade,
  name text not null,
  sequence integer not null check (sequence > 0),
  description text,
  unique (crop_id, sequence),
  unique (crop_id, name)
);

create index crop_stages_crop_sequence_idx on public.crop_stages(crop_id, sequence);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers(id) on delete restrict,
  category_id uuid references public.categories(id) on delete set null,
  name text not null check (length(name) between 2 and 180),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  brand text,
  short_description text,
  description text not null default '',
  specifications jsonb not null default '{}'::jsonb,
  composition jsonb not null default '{}'::jsonb,
  safety_information text,
  status public.product_status not null default 'draft',
  average_rating numeric(3, 2) not null default 0 check (average_rating between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  moderation_note text,
  published_at timestamptz,
  moderated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'published' or published_at is not null)
);

create index products_seller_status_idx on public.products(seller_id, status);
create index products_category_status_idx on public.products(category_id, status);
create index products_published_at_idx on public.products(published_at desc) where status = 'published';

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  sku text not null unique,
  pack_size numeric(12, 3) not null check (pack_size > 0),
  pack_unit text not null check (length(pack_unit) between 1 and 24),
  price numeric(12, 2) not null check (price >= 0),
  currency_code text not null default 'INR' check (currency_code = 'INR'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, pack_size, pack_unit)
);

create index product_variants_product_active_idx on public.product_variants(product_id, is_active);

create table public.inventory (
  variant_id uuid primary key references public.product_variants(id) on delete cascade,
  available_quantity integer not null default 0 check (available_quantity >= 0),
  reserved_quantity integer not null default 0 check (reserved_quantity >= 0),
  updated_at timestamptz not null default now(),
  check (reserved_quantity <= available_quantity)
);

create table public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  quantity_delta integer not null check (quantity_delta <> 0),
  reason text not null check (length(reason) between 2 and 80),
  reference_id uuid,
  actor_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index inventory_movements_variant_created_idx on public.inventory_movements(variant_id, created_at desc);

create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'converted', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index carts_one_active_per_user
  on public.carts(user_id) where status = 'active';

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  quantity integer not null check (quantity between 1 and 999),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, variant_id)
);

create index cart_items_cart_id_idx on public.cart_items(cart_id);

create table public.wishlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create index wishlists_user_created_idx on public.wishlists(user_id, created_at desc);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_id uuid not null references public.profiles(id) on delete restrict,
  status public.order_status not null default 'awaiting_payment',
  payment_status public.payment_status not null default 'pending',
  currency_code text not null default 'INR' check (currency_code = 'INR'),
  subtotal numeric(12, 2) not null check (subtotal >= 0),
  discount_total numeric(12, 2) not null default 0 check (discount_total >= 0),
  shipping_total numeric(12, 2) not null default 0 check (shipping_total >= 0),
  tax_total numeric(12, 2) not null default 0 check (tax_total >= 0),
  grand_total numeric(12, 2) not null check (grand_total >= 0),
  shipping_address_snapshot jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (discount_total <= subtotal),
  check (grand_total = subtotal - discount_total + shipping_total + tax_total)
);

create index orders_customer_created_idx on public.orders(customer_id, created_at desc);
create index orders_status_created_idx on public.orders(status, created_at);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  seller_id uuid not null references public.sellers(id) on delete restrict,
  product_id uuid references public.products(id) on delete set null,
  variant_id uuid references public.product_variants(id) on delete set null,
  product_name_snapshot text not null,
  sku_snapshot text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(14, 2) generated always as (unit_price * quantity) stored,
  created_at timestamptz not null default now()
);

create index order_items_order_id_idx on public.order_items(order_id);
create index order_items_seller_order_idx on public.order_items(seller_id, order_id);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  provider text not null check (provider in ('razorpay', 'cod')),
  provider_order_reference text,
  provider_payment_reference text,
  amount numeric(12, 2) not null check (amount >= 0),
  currency_code text not null default 'INR' check (currency_code = 'INR'),
  status public.payment_status not null default 'pending',
  idempotency_key text not null unique,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index payments_order_created_idx on public.payments(order_id, created_at desc);

create table public.shipments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  seller_id uuid not null references public.sellers(id) on delete restrict,
  status public.shipment_status not null default 'pending',
  carrier text,
  tracking_number text,
  shipped_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index shipments_order_idx on public.shipments(order_id);
create index shipments_seller_status_idx on public.shipments(seller_id, status);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  order_item_id uuid not null unique references public.order_items(id) on delete restrict,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  body text check (body is null or length(body) <= 4000),
  status public.review_status not null default 'pending',
  moderated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index reviews_product_status_created_idx on public.reviews(product_id, status, created_at desc);
create index reviews_reviewer_created_idx on public.reviews(reviewer_id, created_at desc);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  asker_id uuid not null references public.profiles(id) on delete cascade,
  question text not null check (length(question) between 5 and 4000),
  answer text check (answer is null or length(answer) <= 4000),
  answered_at timestamptz,
  status public.review_status not null default 'pending',
  moderated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index questions_product_status_created_idx on public.questions(product_id, status, created_at desc);
create index questions_asker_created_idx on public.questions(asker_id, created_at desc);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code = upper(code)),
  discount_type public.coupon_discount_type not null,
  discount_value numeric(12, 2) not null check (discount_value > 0),
  minimum_order_value numeric(12, 2) not null default 0 check (minimum_order_value >= 0),
  maximum_discount numeric(12, 2) check (maximum_discount is null or maximum_discount >= 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  usage_limit integer check (usage_limit is null or usage_limit > 0),
  per_user_limit integer not null default 1 check (per_user_limit > 0),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check (discount_type <> 'percentage' or discount_value <= 100)
);

create index coupons_active_window_idx on public.coupons(is_active, starts_at, ends_at);

create table public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id) on delete restrict,
  user_id uuid not null references public.profiles(id) on delete restrict,
  order_id uuid not null unique references public.orders(id) on delete restrict,
  redeemed_at timestamptz not null default now(),
  unique (coupon_id, user_id, order_id)
);

create index coupon_redemptions_coupon_user_idx on public.coupon_redemptions(coupon_id, user_id);

create table public.crop_products (
  id uuid primary key default gen_random_uuid(),
  crop_id uuid not null references public.crops(id) on delete cascade,
  crop_stage_id uuid references public.crop_stages(id) on delete set null,
  product_id uuid not null references public.products(id) on delete cascade,
  editorial_note text,
  created_at timestamptz not null default now(),
  unique (crop_id, crop_stage_id, product_id)
);

create index crop_products_crop_stage_idx on public.crop_products(crop_id, crop_stage_id);
create index crop_products_product_idx on public.crop_products(product_id);

create table public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references public.profiles(id) on delete set null,
  title text not null check (length(title) between 2 and 200),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  excerpt text,
  body text not null default '',
  status public.content_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (status <> 'published' or published_at is not null)
);

create index blog_posts_status_published_idx on public.blog_posts(status, published_at desc);
create index blog_posts_author_idx on public.blog_posts(author_id);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (length(kind) between 2 and 80),
  title text not null check (length(title) between 1 and 180),
  body text,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_recipient_unread_idx
  on public.notifications(recipient_id, created_at desc) where read_at is null;

create table public.product_assets (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  object_path text not null unique,
  alt_text text not null default '',
  sort_order integer not null default 0,
  is_approved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index product_assets_product_order_idx on public.product_assets(product_id, sort_order);

create table public.seller_documents (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.sellers(id) on delete cascade,
  object_path text not null unique,
  document_type text not null check (length(document_type) between 2 and 80),
  review_status public.seller_status not null default 'pending',
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index seller_documents_seller_created_idx on public.seller_documents(seller_id, created_at desc);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null check (length(action) between 2 and 120),
  target_table text not null check (length(target_table) between 1 and 80),
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_created_idx on public.audit_logs(created_at desc);
create index audit_logs_target_idx on public.audit_logs(target_table, target_id);
create index audit_logs_actor_created_idx on public.audit_logs(actor_id, created_at desc);

create table public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(title) between 2 and 180),
  subtitle text,
  image_path text,
  destination_path text,
  status public.content_status not null default 'draft',
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index banners_active_sort_idx on public.banners(status, sort_order, starts_at, ends_at);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
revoke all on function public.set_updated_at() from public;

create or replace function public.refresh_product_review_aggregate(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_average numeric(3, 2);
  v_count integer;
begin
  perform 1
  from public.products p
  where p.id = p_product_id
  for update;

  if not found then
    return;
  end if;

  select coalesce(round(avg(r.rating)::numeric, 2), 0)::numeric(3, 2), count(*)::integer
  into v_average, v_count
  from public.reviews r
  where r.product_id = p_product_id and r.status = 'published';

  update public.products
  set average_rating = v_average,
      review_count = v_count,
      updated_at = now()
  where id = p_product_id;
end;
$$;

create or replace function public.sync_product_review_aggregate()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_product_review_aggregate(old.product_id);
    return old;
  end if;

  perform public.refresh_product_review_aggregate(new.product_id);
  if tg_op = 'UPDATE' and old.product_id is distinct from new.product_id then
    perform public.refresh_product_review_aggregate(old.product_id);
  end if;
  return new;
end;
$$;

revoke all on function public.refresh_product_review_aggregate(uuid) from public;
revoke all on function public.sync_product_review_aggregate() from public;

create trigger sync_product_review_aggregate
  after insert or update or delete on public.reviews
  for each row execute function public.sync_product_review_aggregate();

create or replace function public.current_user_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role = 'admin'::public.app_role
  );
$$;

revoke all on function public.current_user_is_admin() from public;
grant execute on function public.current_user_is_admin() to anon, authenticated;

create or replace function public.current_user_owns_seller(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.sellers s
    where s.id = p_seller_id and s.user_id = auth.uid()
  );
$$;

create or replace function public.current_user_is_approved_seller(p_seller_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.sellers s
    where s.id = p_seller_id
      and s.user_id = auth.uid()
      and s.approval_status = 'approved'
  );
$$;

create or replace function public.current_user_owns_seller_path(p_seller_id text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.sellers s
    where s.id::text = p_seller_id and s.user_id = auth.uid()
  );
$$;

create or replace function public.current_user_can_manage_product_path(
  p_seller_id text,
  p_product_id text,
  p_require_approved boolean default false
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.sellers s
    join public.products p on p.seller_id = s.id
    where s.id::text = p_seller_id
      and p.id::text = p_product_id
      and s.user_id = auth.uid()
      and (not p_require_approved or s.approval_status = 'approved')
  );
$$;

revoke all on function public.current_user_owns_seller(uuid) from public;
revoke all on function public.current_user_is_approved_seller(uuid) from public;
revoke all on function public.current_user_owns_seller_path(text) from public;
revoke all on function public.current_user_can_manage_product_path(text, text, boolean) from public;
grant execute on function public.current_user_owns_seller(uuid) to authenticated;
grant execute on function public.current_user_is_approved_seller(uuid) to authenticated;
grant execute on function public.current_user_owns_seller_path(text) to authenticated;
grant execute on function public.current_user_can_manage_product_path(text, text, boolean) to authenticated;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''))
  on conflict (id) do nothing;

  -- Public signup always receives only the farmer role. Seller/admin access is
  -- granted separately by a trusted administrative process.
  insert into public.user_roles (user_id, role)
  values (new.id, 'farmer'::public.app_role)
  on conflict (user_id, role) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_auth_user() from public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'user_roles', 'addresses', 'sellers', 'categories', 'crops',
    'crop_stages', 'products', 'product_variants', 'inventory',
    'inventory_movements', 'carts', 'cart_items', 'wishlists', 'orders',
    'order_items', 'payments', 'shipments', 'reviews', 'questions', 'coupons',
    'coupon_redemptions', 'crop_products', 'blog_posts', 'notifications',
    'product_assets', 'seller_documents', 'audit_logs', 'banners'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
  end loop;
end $$;

create policy profiles_select_own_or_admin on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.current_user_is_admin());
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy user_roles_select_own_or_admin on public.user_roles
  for select to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin());

create policy addresses_owner_all on public.addresses
  for all to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin())
  with check (user_id = auth.uid() or public.current_user_is_admin());

create policy sellers_public_approved on public.sellers
  for select to anon, authenticated
  using (approval_status = 'approved');
create policy sellers_owner_select on public.sellers
  for select to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin());
create policy sellers_owner_update_pending on public.sellers
  for update to authenticated
  using (user_id = auth.uid() and approval_status in ('pending', 'rejected'))
  with check (user_id = auth.uid() and approval_status in ('pending', 'rejected'));
create policy sellers_admin_all on public.sellers
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy categories_public_active on public.categories
  for select to anon, authenticated
  using (is_active or public.current_user_is_admin());
create policy categories_admin_all on public.categories
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy crops_public_published on public.crops
  for select to anon, authenticated
  using (is_published or public.current_user_is_admin());
create policy crops_admin_all on public.crops
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy crop_stages_public_for_published_crop on public.crop_stages
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.crops c
      where c.id = crop_id and (c.is_published or public.current_user_is_admin())
    )
  );
create policy crop_stages_admin_all on public.crop_stages
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy products_public_published on public.products
  for select to anon, authenticated
  using (
    status = 'published'
    and published_at is not null
    and published_at <= now()
  );
create policy products_owner_select on public.products
  for select to authenticated
  using (
    public.current_user_owns_seller(seller_id)
    or public.current_user_is_admin()
  );
create policy products_owner_insert_draft on public.products
  for insert to authenticated
  with check (
    status = 'draft'
    and public.current_user_is_approved_seller(seller_id)
  );
create policy products_owner_update_unpublished on public.products
  for update to authenticated
  using (
    status in ('draft', 'rejected')
    and public.current_user_owns_seller(seller_id)
  )
  with check (
    status in ('draft', 'rejected')
    and public.current_user_owns_seller(seller_id)
  );
create policy products_admin_all on public.products
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy product_variants_public_active on public.product_variants
  for select to anon, authenticated
  using (
    is_active
    and exists (
      select 1 from public.products p
      where p.id = product_id
        and p.status = 'published'
        and p.published_at is not null
        and p.published_at <= now()
    )
  );
create policy product_variants_owner_all on public.product_variants
  for all to authenticated
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_is_approved_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  )
  with check (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_is_approved_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  );

create policy inventory_seller_read on public.inventory
  for select to authenticated
  using (
    exists (
      select 1 from public.product_variants v
      join public.products p on p.id = v.product_id
      where v.id = variant_id and public.current_user_owns_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  );

create policy inventory_movements_seller_read on public.inventory_movements
  for select to authenticated
  using (
    exists (
      select 1 from public.product_variants v
      join public.products p on p.id = v.product_id
      where v.id = variant_id and public.current_user_owns_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  );

create policy carts_owner_all on public.carts
  for all to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin())
  with check (user_id = auth.uid() or public.current_user_is_admin());

create policy cart_items_owner_all on public.cart_items
  for all to authenticated
  using (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and (c.user_id = auth.uid() or public.current_user_is_admin())
    )
  )
  with check (
    exists (
      select 1 from public.carts c
      where c.id = cart_id and (c.user_id = auth.uid() or public.current_user_is_admin())
    )
    and exists (
      select 1 from public.product_variants v
      join public.products p on p.id = v.product_id
      where v.id = variant_id
        and v.is_active
        and p.status = 'published'
    )
  );

create policy wishlists_owner_all on public.wishlists
  for all to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin())
  with check (
    (user_id = auth.uid() or public.current_user_is_admin())
    and exists (
      select 1 from public.products p
      where p.id = product_id and p.status = 'published'
    )
  );

create policy orders_customer_read on public.orders
  for select to authenticated
  using (customer_id = auth.uid() or public.current_user_is_admin());

create policy order_items_customer_or_seller_read on public.order_items
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.customer_id = auth.uid()
    )
    or exists (
      select 1 where public.current_user_owns_seller(seller_id)
    )
    or public.current_user_is_admin()
  );

create policy payments_customer_read on public.payments
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and (o.customer_id = auth.uid() or public.current_user_is_admin())
    )
  );

create policy shipments_customer_or_seller_read on public.shipments
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_id and o.customer_id = auth.uid()
    )
    or exists (
      select 1 where public.current_user_owns_seller(seller_id)
    )
    or public.current_user_is_admin()
  );

create policy reviews_public_published on public.reviews
  for select to anon, authenticated
  using (status = 'published');
create policy reviews_customer_insert_eligible on public.reviews
  for insert to authenticated
  with check (
    reviewer_id = auth.uid()
    and status = 'pending'
    and exists (
      select 1
      from public.order_items oi
      join public.orders o on o.id = oi.order_id
      where oi.id = order_item_id
        and oi.product_id = reviews.product_id
        and o.customer_id = auth.uid()
        and o.status = 'delivered'
    )
  );
create policy reviews_customer_update_pending on public.reviews
  for update to authenticated
  using (reviewer_id = auth.uid() and status = 'pending')
  with check (reviewer_id = auth.uid() and status = 'pending');
create policy reviews_admin_all on public.reviews
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy questions_public_approved on public.questions
  for select to anon, authenticated
  using (status = 'published');
create policy questions_asker_insert on public.questions
  for insert to authenticated
  with check (asker_id = auth.uid() and status = 'pending');
create policy questions_asker_read on public.questions
  for select to authenticated
  using (asker_id = auth.uid());
create policy questions_seller_read on public.questions
  for select to authenticated
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_owns_seller(p.seller_id)
    )
  );
create policy questions_seller_answer on public.questions
  for update to authenticated
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_is_approved_seller(p.seller_id)
    )
  )
  with check (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_is_approved_seller(p.seller_id)
    )
  );
create policy questions_admin_all on public.questions
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy coupons_admin_all on public.coupons
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy coupon_redemptions_owner_read on public.coupon_redemptions
  for select to authenticated
  using (user_id = auth.uid() or public.current_user_is_admin());

create policy crop_products_public_relevant on public.crop_products
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.crops c where c.id = crop_id and c.is_published
    )
    and exists (
      select 1 from public.products p
      where p.id = product_id
        and p.status = 'published'
        and p.published_at is not null
        and p.published_at <= now()
    )
  );
create policy crop_products_admin_all on public.crop_products
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy blog_posts_public_published on public.blog_posts
  for select to anon, authenticated
  using (status = 'published' and published_at is not null and published_at <= now());
create policy blog_posts_admin_all on public.blog_posts
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy notifications_recipient_read on public.notifications
  for select to authenticated
  using (recipient_id = auth.uid() or public.current_user_is_admin());
create policy notifications_recipient_mark_read on public.notifications
  for update to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

create policy product_assets_public_published on public.product_assets
  for select to anon, authenticated
  using (
    is_approved
    and exists (
      select 1 from public.products p
      where p.id = product_id
        and p.status = 'published'
        and p.published_at is not null
        and p.published_at <= now()
    )
  );
create policy product_assets_seller_manage on public.product_assets
  for all to authenticated
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_owns_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  )
  with check (
    exists (
      select 1 from public.products p
      where p.id = product_id and public.current_user_owns_seller(p.seller_id)
    )
    or public.current_user_is_admin()
  );

create policy seller_documents_owner_or_admin_read on public.seller_documents
  for select to authenticated
  using (
    exists (
      select 1 where public.current_user_owns_seller(seller_id)
    )
    or public.current_user_is_admin()
  );
create policy seller_documents_owner_insert on public.seller_documents
  for insert to authenticated
  with check (
    review_status = 'pending'
    and public.current_user_owns_seller(seller_id)
  );
create policy seller_documents_admin_update on public.seller_documents
  for update to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy audit_logs_admin_read on public.audit_logs
  for select to authenticated
  using (public.current_user_is_admin());

create policy banners_public_active on public.banners
  for select to anon, authenticated
  using (
    status = 'published'
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at > now())
  );
create policy banners_admin_all on public.banners
  for all to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

-- Narrow, authenticated admin RPCs handle fields that sellers and customers
-- must never change directly. The first admin is bootstrapped manually in the
-- Supabase SQL editor after an identity has been verified.
create or replace function public.admin_grant_role(p_user_id uuid, p_role public.app_role)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  insert into public.user_roles (user_id, role, granted_by)
  values (p_user_id, p_role, auth.uid())
  on conflict (user_id, role) do nothing;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (
    auth.uid(),
    'grant_role',
    'user_roles',
    p_user_id,
    jsonb_build_object('role', p_role::text)
  );
end;
$$;

create or replace function public.admin_remove_role(p_user_id uuid, p_role public.app_role)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_admin_count integer;
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtext('kisanmart-admin-role'));
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  if p_role = 'admin'::public.app_role then
    select count(*)::integer
    into v_admin_count
    from public.user_roles
    where role = 'admin'::public.app_role;

    if v_admin_count <= 1 then
      raise exception 'The final administrator role cannot be removed' using errcode = '23514';
    end if;
  end if;

  delete from public.user_roles
  where user_id = p_user_id and role = p_role;

  if not found then
    raise exception 'Role assignment not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'remove_role', 'user_roles', p_user_id,
    jsonb_build_object('role', p_role::text));
end;
$$;

create or replace function public.admin_set_seller_status(
  p_seller_id uuid,
  p_status public.seller_status,
  p_moderation_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.sellers
  set approval_status = p_status,
      approved_at = case when p_status = 'approved' then now() else null end,
      approved_by = case when p_status = 'approved' then auth.uid() else null end,
      moderation_note = left(p_moderation_note, 2000),
      updated_at = now()
  where id = p_seller_id;

  if not found then
    raise exception 'Seller not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'seller_status_changed', 'sellers', p_seller_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

create or replace function public.admin_set_product_status(
  p_product_id uuid,
  p_status public.product_status,
  p_moderation_note text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.products
  set status = p_status,
      published_at = case
        when p_status = 'published' then coalesce(published_at, now())
        else null
      end,
      moderation_note = left(p_moderation_note, 2000),
      moderated_by = auth.uid(),
      updated_at = now()
  where id = p_product_id;

  if not found then
    raise exception 'Product not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'product_status_changed', 'products', p_product_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

create or replace function public.admin_set_asset_approval(p_asset_id uuid, p_approved boolean)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.product_assets
  set is_approved = p_approved,
      updated_at = now()
  where id = p_asset_id;

  if not found then
    raise exception 'Product asset not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'product_asset_reviewed', 'product_assets', p_asset_id,
    jsonb_build_object('approved', p_approved));
end;
$$;

create or replace function public.admin_set_review_status(
  p_review_id uuid,
  p_status public.review_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.reviews
  set status = p_status,
      moderated_by = auth.uid(),
      updated_at = now()
  where id = p_review_id;

  if not found then
    raise exception 'Review not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'review_status_changed', 'reviews', p_review_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

create or replace function public.admin_set_question_status(
  p_question_id uuid,
  p_status public.review_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.questions
  set status = p_status,
      moderated_by = auth.uid(),
      updated_at = now()
  where id = p_question_id;

  if not found then
    raise exception 'Question not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'question_status_changed', 'questions', p_question_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

create or replace function public.admin_set_seller_document_status(
  p_document_id uuid,
  p_status public.seller_status
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.current_user_is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;

  update public.seller_documents
  set review_status = p_status,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = p_document_id;

  if not found then
    raise exception 'Seller document not found' using errcode = 'P0002';
  end if;

  insert into public.audit_logs (actor_id, action, target_table, target_id, metadata)
  values (auth.uid(), 'seller_document_status_changed', 'seller_documents', p_document_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

revoke all on function public.admin_grant_role(uuid, public.app_role) from public;
revoke all on function public.admin_remove_role(uuid, public.app_role) from public;
revoke all on function public.admin_set_seller_status(uuid, public.seller_status, text) from public;
revoke all on function public.admin_set_product_status(uuid, public.product_status, text) from public;
revoke all on function public.admin_set_asset_approval(uuid, boolean) from public;
revoke all on function public.admin_set_review_status(uuid, public.review_status) from public;
revoke all on function public.admin_set_question_status(uuid, public.review_status) from public;
revoke all on function public.admin_set_seller_document_status(uuid, public.seller_status) from public;
grant execute on function public.admin_grant_role(uuid, public.app_role) to authenticated;
grant execute on function public.admin_remove_role(uuid, public.app_role) to authenticated;
grant execute on function public.admin_set_seller_status(uuid, public.seller_status, text) to authenticated;
grant execute on function public.admin_set_product_status(uuid, public.product_status, text) to authenticated;
grant execute on function public.admin_set_asset_approval(uuid, boolean) to authenticated;
grant execute on function public.admin_set_review_status(uuid, public.review_status) to authenticated;
grant execute on function public.admin_set_question_status(uuid, public.review_status) to authenticated;
grant execute on function public.admin_set_seller_document_status(uuid, public.seller_status) to authenticated;

-- Table privileges are intentionally narrower than RLS alone. Revoke only
-- KisanMart tables so existing Supabase public objects are left untouched.
do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'user_roles', 'addresses', 'sellers', 'categories', 'crops',
    'crop_stages', 'products', 'product_variants', 'inventory',
    'inventory_movements', 'carts', 'cart_items', 'wishlists', 'orders',
    'order_items', 'payments', 'shipments', 'reviews', 'questions', 'coupons',
    'coupon_redemptions', 'crop_products', 'blog_posts', 'notifications',
    'product_assets', 'seller_documents', 'audit_logs', 'banners'
  ]
  loop
    execute format('revoke all on table public.%I from anon, authenticated', table_name);
  end loop;
end $$;

grant usage on schema public to anon, authenticated;

grant select (id, full_name, phone, locale, created_at, updated_at) on public.profiles to authenticated;
grant update (full_name, phone, locale) on public.profiles to authenticated;
grant select (user_id, role, granted_at) on public.user_roles to authenticated;
grant select (id, recipient_name, phone, address_line_1, address_line_2, locality, city, state, postal_code, country_code, delivery_instructions, is_default, created_at, updated_at),
  insert (user_id, recipient_name, phone, address_line_1, address_line_2, locality, city, state, postal_code, country_code, delivery_instructions, is_default),
  update (recipient_name, phone, address_line_1, address_line_2, locality, city, state, postal_code, country_code, delivery_instructions, is_default),
  delete on public.addresses to authenticated;

grant select (id, business_name, slug, description, state, approval_status, created_at) on public.sellers to anon, authenticated;
grant update (business_name, description, support_email, support_phone, state) on public.sellers to authenticated;
grant update (approval_status, approved_at, approved_by, moderation_note) on public.sellers to authenticated;
grant select (id, parent_id, name, slug, description, sort_order) on public.categories to anon, authenticated;
grant select (id, name, slug, scientific_name, description) on public.crops to anon, authenticated;
grant select (id, crop_id, name, sequence, description) on public.crop_stages to anon, authenticated;
grant insert, update, delete on public.categories, public.crops, public.crop_stages,
  public.crop_products, public.blog_posts, public.banners to authenticated;

grant select (id, seller_id, category_id, name, slug, brand, short_description, description, specifications, composition, safety_information, status, average_rating, review_count, published_at, created_at, updated_at)
  on public.products to anon, authenticated;
grant insert (seller_id, category_id, name, slug, brand, short_description, description, specifications, composition, safety_information)
  on public.products to authenticated;
grant update (category_id, name, slug, brand, short_description, description, specifications, composition, safety_information)
  on public.products to authenticated;
grant select (id, product_id, sku, pack_size, pack_unit, price, currency_code, is_active, created_at, updated_at)
  on public.product_variants to anon, authenticated;
grant insert (product_id, sku, pack_size, pack_unit, price, currency_code, is_active)
  on public.product_variants to authenticated;
grant update (sku, pack_size, pack_unit, price, currency_code, is_active)
  on public.product_variants to authenticated;
grant delete on public.product_variants to authenticated;
grant select (variant_id, available_quantity, updated_at) on public.inventory to authenticated;
grant select (id, variant_id, quantity_delta, reason, reference_id, created_at)
  on public.inventory_movements to authenticated;

grant select (id, user_id, status, created_at, updated_at), insert (user_id)
  on public.carts to authenticated;
grant select (id, cart_id, variant_id, quantity, created_at, updated_at),
  insert (cart_id, variant_id, quantity), update (quantity), delete
  on public.cart_items to authenticated;
grant select (id, user_id, product_id, created_at), insert (user_id, product_id), delete
  on public.wishlists to authenticated;

grant select (id, order_number, customer_id, status, payment_status, currency_code, subtotal, discount_total, shipping_total, tax_total, grand_total, shipping_address_snapshot, created_at, updated_at)
  on public.orders to authenticated;
grant select (id, order_id, seller_id, product_id, variant_id, product_name_snapshot, sku_snapshot, quantity, unit_price, line_total, created_at)
  on public.order_items to authenticated;
grant select (id, order_id, amount, currency_code, status, created_at, updated_at)
  on public.payments to authenticated;
grant select (id, order_id, seller_id, status, carrier, tracking_number, shipped_at, delivered_at, created_at, updated_at)
  on public.shipments to authenticated;

grant select (id, product_id, rating, body, status, created_at)
  on public.reviews to anon, authenticated;
grant insert (product_id, order_item_id, reviewer_id, rating, body),
  update (rating, body)
  on public.reviews to authenticated;
grant select (id, product_id, question, answer, answered_at, status, created_at)
  on public.questions to anon, authenticated;
grant insert (product_id, asker_id, question) on public.questions to authenticated;
grant update (answer, answered_at) on public.questions to authenticated;

grant select (id, coupon_id, user_id, order_id, redeemed_at) on public.coupon_redemptions to authenticated;
grant select (id, crop_id, crop_stage_id, product_id, editorial_note, created_at) on public.crop_products to anon, authenticated;
grant select (id, author_id, title, slug, excerpt, body, published_at, created_at, updated_at) on public.blog_posts to anon, authenticated;
grant select (id, recipient_id, kind, title, body, payload, read_at, created_at),
  update (read_at) on public.notifications to authenticated;
grant select (id, product_id, object_path, alt_text, sort_order, is_approved, created_at, updated_at)
  on public.product_assets to anon, authenticated;
grant insert (product_id, object_path, alt_text, sort_order),
  update (object_path, alt_text, sort_order), delete
  on public.product_assets to authenticated;
grant select (id, seller_id, object_path, document_type, review_status, reviewed_at, created_at),
  insert (seller_id, object_path, document_type)
  on public.seller_documents to authenticated;
grant select (id, actor_id, action, target_table, target_id, metadata, created_at)
  on public.audit_logs to authenticated;
grant select (id, title, subtitle, image_path, destination_path, starts_at, ends_at, sort_order)
  on public.banners to anon, authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'addresses', 'sellers', 'categories', 'crops', 'products',
    'product_variants', 'carts', 'cart_items', 'wishlists', 'orders',
    'shipments', 'reviews', 'questions', 'blog_posts', 'notifications',
    'product_assets', 'seller_documents', 'banners'
  ]
  loop
    execute format(
      'create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      table_name
    );
  end loop;
end $$;

-- Private buckets: product objects are readable through object-level RLS only
-- after the related product and asset are published/approved.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('seller-documents', 'seller-documents', false, 15728640, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy product_images_published_read on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'product-images'
    and exists (
      select 1
      from public.product_assets pa
      join public.products p on p.id = pa.product_id
      where pa.object_path = name
        and pa.is_approved
        and p.status = 'published'
        and p.published_at is not null
        and p.published_at <= now()
    )
  );

create policy product_images_approved_seller_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and public.current_user_can_manage_product_path(
      (storage.foldername(name))[1],
      (storage.foldername(name))[2],
      true
    )
  );

create policy product_images_seller_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'product-images'
    and public.current_user_can_manage_product_path(
      (storage.foldername(name))[1],
      (storage.foldername(name))[2],
      true
    )
  )
  with check (
    bucket_id = 'product-images'
    and public.current_user_can_manage_product_path(
      (storage.foldername(name))[1],
      (storage.foldername(name))[2],
      true
    )
  );

create policy product_images_seller_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'product-images'
    and public.current_user_can_manage_product_path(
      (storage.foldername(name))[1],
      (storage.foldername(name))[2],
      false
    )
  );

create policy seller_documents_owner_upload on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'seller-documents'
    and public.current_user_owns_seller_path((storage.foldername(name))[1])
  );

create policy seller_documents_owner_or_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'seller-documents'
    and (
      public.current_user_owns_seller_path((storage.foldername(name))[1])
      or public.current_user_is_admin()
    )
  );

create policy seller_documents_admin_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'seller-documents'
    and public.current_user_is_admin()
  );

commit;
