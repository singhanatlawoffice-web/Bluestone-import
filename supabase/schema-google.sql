-- ============================================================
--  จำกัดสิทธิ์หลังเปิดให้เข้าด้วยบัญชี Google
--
--  ปัญหา: พอเปิด provider Google ใน Supabase แล้ว ใครก็ตามที่มีบัญชี Google
--  กดปุ่มก็ได้ session เป็น authenticated ทันที ถ้านโยบายเดิมเขียนว่า
--  "authenticated ทำได้ทุกอย่าง" เท่ากับเปิดข้อมูลเงินของบริษัทให้คนนอก
--
--  ไฟล์นี้เปลี่ยนนโยบายเป็น "ต้องเป็น authenticated และอีเมลต้องมีอยู่ใน
--  ตาราง app_users ด้วย" การเช็กในหน้าเว็บอย่างเดียวกันไม่ได้จริง
--  เพราะคนที่รู้วิธียิง API ตรงจะข้ามหน้าเว็บไปเลย ต้องกันที่ชั้นนี้
--
--  วิธีใช้: เปิด Supabase > SQL Editor > วางทั้งไฟล์ > Run
--  ต้องมีอีเมลของตัวเองอยู่ใน app_users ก่อน ไม่อย่างนั้นจะล็อกตัวเองออก
-- ============================================================

-- ---------- 1) ฟังก์ชันตรวจว่าอีเมลที่ล็อกอินอยู่ได้รับสิทธิ์หรือยัง ----------
-- security definer เพื่อให้ฟังก์ชันอ่าน app_users ได้โดยไม่ติด RLS ของตัวเอง
create or replace function public.is_allowed_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.app_users u
    where u.email is not null
      and lower(btrim(u.email)) = lower(btrim(coalesce(auth.jwt() ->> 'email', '')))
  );
$$;

revoke all on function public.is_allowed_user() from public;
grant execute on function public.is_allowed_user() to authenticated;

-- ---------- 2) เปลี่ยนนโยบายทุกตารางให้ผ่านด่านนี้ ----------
do $$
declare t text;
begin
  foreach t in array array['app_settings','customers','entries','app_users','activity_log','trip_photos'] loop
    if to_regclass('public.' || t) is null then
      raise notice 'ข้ามตาราง % เพราะยังไม่มีในฐานข้อมูล', t;
      continue;
    end if;
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_anon_all', t);
    execute format('drop policy if exists %I on public.%I', t || '_auth_all', t);
    execute format('drop policy if exists %I on public.%I', t || '_allowed', t);
    execute format(
      'create policy %I on public.%I for all to authenticated '
      'using (public.is_allowed_user()) with check (public.is_allowed_user())',
      t || '_allowed', t);
  end loop;
end $$;

-- ---------- 3) ตรวจผล ----------
-- ต้องเห็นเฉพาะ policy ลงท้าย _allowed และ roles = {authenticated}
select tablename, policyname, roles, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- ---------- 4) ตรวจว่าอีเมลตัวเองอยู่ในรายชื่อแล้ว ----------
-- แก้อีเมลข้างล่างเป็นของตัวเองก่อนรัน
-- select * from public.app_users where lower(email) = lower('somchai@bluestone.co.th');

-- ---------- หมายเหตุที่ยังไม่ได้ทำในไฟล์นี้ ----------
-- รูปในที่เก็บไฟล์ (storage bucket ชื่อ trip-photos) มีนโยบายของตัวเองแยกต่างหาก
-- อยู่ในไฟล์ schema-photos.sql ถ้าต้องการให้ใช้ด่านเดียวกัน ต้องแก้นโยบายของ
-- storage.objects ให้เรียก public.is_allowed_user() เพิ่มด้วย
