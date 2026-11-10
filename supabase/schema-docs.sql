-- ============================================================
--  ที่เก็บเอกสารแนบของรอบนำเข้า (bucket ชื่อ round-docs)
--
--  ตัวไฟล์ที่แนบในหน้าสตอกจะถูกเก็บสองที่
--    1) IndexedDB ของเครื่องที่แนบ เปิดได้ทันทีแม้ไม่มีเน็ต
--    2) ถัง round-docs ของ Supabase เพื่อให้เครื่องอื่นเปิดได้
--  ส่วนรายชื่อเอกสาร (ชื่อไฟล์ ชนิด ขนาด) เก็บอยู่ในตัวรอบนำเข้าเอง
--  จึงซิงก์ไปพร้อมข้อมูลรอบโดยไม่ต้องมีตารางเพิ่ม
--
--  ถังนี้เป็นแบบส่วนตัว เปิดไฟล์ได้ด้วย signed URL อายุ 10 นาทีเท่านั้น
--  ใครที่ไม่มีอีเมลอยู่ใน app_users จะอ่านไม่ได้เลย
--
--  วิธีใช้: เปิด Supabase > SQL Editor > วางทั้งไฟล์ > Run
--  ต้องรัน schema-google.sql ก่อน เพราะไฟล์นี้เรียกใช้ public.is_allowed_user()
-- ============================================================

-- ---------- 1) สร้างถัง ----------
insert into storage.buckets (id, name, public)
values ('round-docs', 'round-docs', false)
on conflict (id) do update set public = false;

-- ---------- 2) นโยบายการเข้าถึง ----------
-- ล้างของเดิมก่อน เพื่อให้รันซ้ำได้โดยไม่พัง
drop policy if exists round_docs_read   on storage.objects;
drop policy if exists round_docs_insert on storage.objects;
drop policy if exists round_docs_update on storage.objects;
drop policy if exists round_docs_delete on storage.objects;

create policy round_docs_read on storage.objects
  for select to authenticated
  using (bucket_id = 'round-docs' and public.is_allowed_user());

create policy round_docs_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'round-docs' and public.is_allowed_user());

create policy round_docs_update on storage.objects
  for update to authenticated
  using (bucket_id = 'round-docs' and public.is_allowed_user())
  with check (bucket_id = 'round-docs' and public.is_allowed_user());

create policy round_docs_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'round-docs' and public.is_allowed_user());

-- ---------- 3) ตรวจผล ----------
select id, public from storage.buckets where id = 'round-docs';

select policyname, cmd, roles
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'round_docs%'
order by policyname;

-- ---------- หมายเหตุ ----------
-- ถ้ายังไม่รันไฟล์นี้ การแนบเอกสารยังใช้งานได้ตามปกติ
-- แต่ไฟล์จะอยู่เฉพาะในเครื่องที่แนบ เครื่องอื่นจะเห็นชื่อไฟล์แต่เปิดไม่ได้
-- ในตารางจะขึ้นป้ายว่า "เก็บในเครื่องนี้" แทน "ขึ้นเซิร์ฟเวอร์แล้ว"
