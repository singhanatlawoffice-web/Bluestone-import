-- ============================================================
-- Blue Stone Import · โครงสร้างฐานข้อมูล Supabase
-- รันไฟล์นี้ใน Supabase Studio > SQL Editor > New query > Run
-- ============================================================

-- ---------- 1) อัตราและชื่อคู่ค้า (เก็บแถวเดียว) ----------
create table if not exists public.app_settings (
  id          text primary key default 'default',
  rates       jsonb not null default '{}'::jsonb,
  names       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- ---------- 2) ลูกค้าปลายทาง ----------
create table if not exists public.customers (
  id          text primary key,
  name        text not null,
  tax_id      text,
  phone       text,
  contact     text,
  hno         text,
  moo         text,
  road        text,
  tambon      text,
  amphoe      text,
  province    text,
  zip         text,
  gps         text,
  updated_at  timestamptz not null default now()
);
create index if not exists customers_name_idx on public.customers (name);

-- ---------- 3) รายการเคลื่อนไหว (เงินเข้า ปูนเข้า ส่งมอบ ขาย) ----------
-- kind: depositF | depositJ | import | saleBuyer | saleOther
create table if not exists public.entries (
  id           bigint primary key,
  entry_date   date not null,
  kind         text not null,
  amount       numeric,          -- ใช้กับ depositF / depositJ
  note         text,
  cement_type  text,             -- powder | bag  (ใช้กับการขาย)
  tons         numeric,          -- ใช้กับการขาย
  price        numeric,          -- ราคาขายต่อตัน
  who          text,             -- ชื่อลูกค้ารายอื่น
  trucks       jsonb,            -- คู่รถทั้งหมดของวันนั้น (ใช้กับ import)
  updated_at   timestamptz not null default now()
);
create index if not exists entries_date_idx on public.entries (entry_date);
create index if not exists entries_kind_idx on public.entries (kind);

-- ---------- 4) ผู้ใช้งาน ----------
create table if not exists public.app_users (
  id          text primary key,
  name        text not null,
  role        text,
  email       text,
  updated_at  timestamptz not null default now()
);

-- ---------- 5) ประวัติการใช้งานและการแก้ไข ----------
create table if not exists public.activity_log (
  id       bigserial primary key,
  at       timestamptz not null default now(),
  who      text,
  role     text,
  act      text,
  detail   text
);
create index if not exists activity_log_at_idx on public.activity_log (at desc);

-- ============================================================
-- Row Level Security
-- ------------------------------------------------------------
-- ค่าตั้งต้นด้านล่างเปิดให้ anon key อ่านและเขียนได้ทุกตาราง
-- เพื่อให้หน้าเว็บใช้งานได้ทันทีโดยยังไม่ต้องทำระบบล็อกอิน
--
-- *** ข้อควรระวัง ***
-- ใครก็ตามที่ได้ URL + anon key ไป จะอ่านและแก้ข้อมูลได้ทั้งหมด
-- เมื่อพร้อมใช้งานจริง ให้เปิด Supabase Auth แล้วสลับไปใช้
-- นโยบายชุดที่คอมเมนต์ไว้ท้ายไฟล์ (จำกัดเฉพาะผู้ล็อกอิน)
-- ============================================================
alter table public.app_settings enable row level security;
alter table public.customers    enable row level security;
alter table public.entries      enable row level security;
alter table public.app_users    enable row level security;
alter table public.activity_log enable row level security;

do $$
declare t text;
begin
  foreach t in array array['app_settings','customers','entries','app_users','activity_log'] loop
    execute format('drop policy if exists %I on public.%I', t || '_anon_all', t);
    execute format(
      'create policy %I on public.%I for all to anon using (true) with check (true)',
      t || '_anon_all', t);
  end loop;
end $$;

-- ============================================================
-- ชุดนโยบายสำหรับตอนเปิดระบบล็อกอินแล้ว (ยังไม่เปิดใช้)
-- ============================================================
-- do $$
-- declare t text;
-- begin
--   foreach t in array array['app_settings','customers','entries','app_users','activity_log'] loop
--     execute format('drop policy if exists %I on public.%I', t || '_anon_all', t);
--     execute format(
--       'create policy %I on public.%I for all to authenticated using (true) with check (true)',
--       t || '_auth_all', t);
--   end loop;
-- end $$;
