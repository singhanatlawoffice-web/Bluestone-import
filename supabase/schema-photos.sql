-- ============================================================
-- Blue Stone Import · ระบบรูปถ่ายจากพนักงานขับรถ
-- รันไฟล์นี้ต่อจาก schema.sql (รันซ้ำได้ ไม่พัง)
-- ------------------------------------------------------------
-- เก็บอะไร
--   รูปที่คนขับถ่ายส่งเข้ามา 3 ขั้น  p = รับปูนที่โรงงาน
--                                  b = ใบชั่งและใบขนส่ง
--                                  d = ส่งปูนให้ลูกค้า
--   เวลาที่บันทึกคือเวลาที่รูปเข้าเซิร์ฟเวอร์ ไม่ใช่เวลาที่คนขับพิมพ์เอง
--   จอ TV ใช้รูปขั้น d เป็นตัวตัดสินว่า "ส่งถึงแล้ว"
-- ============================================================

create table if not exists public.trip_photos (
  id         bigserial primary key,
  job        text not null,                 -- เลขใบงาน เช่น BT-0001
  kind       text not null check (kind in ('p','b','d')),
  token      text not null,                 -- รหัสลับในลิงก์ กันคนอื่นยิงมั่ว
  path       text not null,                 -- ที่อยู่ไฟล์ในถัง storage
  url        text,                          -- ลิงก์เปิดดูรูป
  note       text,
  plate      text,
  media      text not null default 'photo',   -- photo | video
  source     text not null default 'camera',  -- camera = ถ่ายผ่านระบบ · gallery = เลือกไฟล์เอง
  flag       text,                            -- ข้อความเตือน เช่น ไม่ได้ถ่ายผ่านระบบ
  lat        double precision,
  lng        double precision,
  acc        integer,                         -- ความแม่นยำพิกัด เป็นเมตร
  place      text,
  duration   integer,                         -- ความยาววิดีโอ วินาที
  taken_at   timestamptz,                     -- เวลาที่ถ่าย (จากเครื่อง อาจแก้ได้)
  at         timestamptz not null default now()  -- เวลาที่เซิร์ฟเวอร์รับไฟล์ แก้ไม่ได้
);
-- รันซ้ำบนฐานข้อมูลที่สร้างไว้ก่อนหน้า
alter table public.trip_photos add column if not exists media    text not null default 'photo';
alter table public.trip_photos add column if not exists source   text not null default 'camera';
alter table public.trip_photos add column if not exists flag     text;
alter table public.trip_photos add column if not exists lat      double precision;
alter table public.trip_photos add column if not exists lng      double precision;
alter table public.trip_photos add column if not exists acc      integer;
alter table public.trip_photos add column if not exists place    text;
alter table public.trip_photos add column if not exists duration integer;
alter table public.trip_photos add column if not exists taken_at timestamptz;
create index if not exists trip_photos_job_idx  on public.trip_photos (job);
create index if not exists trip_photos_kind_idx on public.trip_photos (job, kind);
create index if not exists trip_photos_at_idx   on public.trip_photos (at desc);

alter table public.trip_photos enable row level security;

-- คนขับไม่ได้ล็อกอิน จึงต้องให้ anon "เพิ่มได้อย่างเดียว"
-- อ่านย้อนหลังไม่ได้ ลบไม่ได้ แก้ไม่ได้
drop policy if exists trip_photos_anon_insert on public.trip_photos;
create policy trip_photos_anon_insert on public.trip_photos
  for insert to anon with check (true);

-- พนักงานที่ล็อกอินแล้ว อ่านและจัดการได้เต็ม (จอ TV กับหน้าเว็บใช้ทางนี้)
drop policy if exists trip_photos_auth_all on public.trip_photos;
create policy trip_photos_auth_all on public.trip_photos
  for all to authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- ถังเก็บไฟล์รูป
-- ------------------------------------------------------------
-- ถังปิด (public = false) เปิดรูปได้เฉพาะผ่านลิงก์ชั่วคราวที่หน้าเว็บขอให้ หลังล็อกอินแล้วเท่านั้น
insert into storage.buckets (id, name, public)
values ('trip-photos', 'trip-photos', false)
on conflict (id) do update set public = false;

-- คนขับอัปโหลดได้ แต่ลบหรือทับของเดิมไม่ได้
drop policy if exists trip_photos_upload on storage.objects;
create policy trip_photos_upload on storage.objects
  for insert to anon with check (bucket_id = 'trip-photos');

-- คนขับอัปโหลดได้อย่างเดียว เปิดดูย้อนหลังไม่ได้
drop policy if exists trip_photos_read on storage.objects;
create policy trip_photos_read on storage.objects
  for select to authenticated using (bucket_id = 'trip-photos');

drop policy if exists trip_photos_manage on storage.objects;
create policy trip_photos_manage on storage.objects
  for all to authenticated using (bucket_id = 'trip-photos') with check (bucket_id = 'trip-photos');

-- ============================================================
-- ข้อควรรู้เรื่องความปลอดภัย พูดกันตรง ๆ
-- ------------------------------------------------------------
-- 1) ถังนี้เป็นแบบปิด เปิดรูปตรง ๆ จาก URL ไม่ได้
--    หน้า photos.html จะขอลิงก์ชั่วคราวอายุ 1 ชั่วโมงให้ หลังจากล็อกอินแล้วเท่านั้น
--    ถ้าลิงก์หลุดออกไป มันก็หมดอายุเองภายในหนึ่งชั่วโมง
-- 2) source บอกที่มาของไฟล์
--    camera  = ถ่ายผ่านหน้าเว็บ มีลายประทับพิกัดและเวลาเผาลงบนภาพ
--    gallery = คนขับเลือกไฟล์เอง (ใช้เฉพาะตอนเปิดกล้องในหน้าเว็บไม่ได้)
--              แถวนี้จะมี flag ติดไว้ และจอ TV จะขึ้นธงแดงให้เห็น
--    เวลาที่เชื่อถือได้คือ at (เซิร์ฟเวอร์บันทึก) ไม่ใช่ taken_at ซึ่งมาจากเครื่องคนขับ
-- 3) anon เพิ่มรูปได้โดยไม่ต้องล็อกอิน เพราะคนขับไม่มีบัญชี
--    หมายความว่าคนที่รู้ลิงก์สามารถยิงรูปเข้ามาได้ ระบบจึงเก็บ token ไว้ทุกแถว
--    ให้ฝั่งออฟฟิศตรวจว่าตรงกับใบงานจริงหรือไม่ก่อนนับเป็นหลักฐาน
-- ============================================================
