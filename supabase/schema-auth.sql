-- ============================================================
-- Blue Stone Import · ปิดสิทธิ์ anon เปลี่ยนเป็นเฉพาะผู้ล็อกอิน
-- ------------------------------------------------------------
-- รันไฟล์นี้ "หลัง" จากที่
--   1) รัน schema.sql สร้างตารางครบแล้ว
--   2) เปิด Supabase Auth แบบอีเมล และเพิ่มผู้ใช้ของบริษัทเรียบร้อย
--   3) ทดสอบล็อกอินเข้าเว็บจริงได้แล้ว
--
-- รันแล้วจะเกิดอะไรขึ้น
--   คนที่มีแต่ URL กับ publishable key แต่ไม่ได้ล็อกอิน จะอ่านและ
--   แก้ข้อมูลไม่ได้อีกต่อไป เหลือเฉพาะผู้ใช้ที่ล็อกอินผ่านหน้า login
--
-- ถ้ารันแล้วเว็บขึ้นว่าดึงข้อมูลไม่สำเร็จ ให้ตรวจว่าล็อกอินอยู่หรือไม่
-- ถ้าต้องการย้อนกลับไปสถานะเดิมชั่วคราว ให้รัน schema.sql ซ้ำ
-- ============================================================

do $$
declare t text;
begin
  foreach t in array array['app_settings','customers','entries','app_users','activity_log'] loop
    execute format('drop policy if exists %I on public.%I', t || '_anon_all', t);
    execute format('drop policy if exists %I on public.%I', t || '_auth_all', t);
    execute format(
      'create policy %I on public.%I for all to authenticated using (true) with check (true)',
      t || '_auth_all', t);
  end loop;
end $$;

-- ตรวจผลลัพธ์: ต้องเห็นเฉพาะ policy ลงท้าย _auth_all และ roles = {authenticated}
select tablename, policyname, roles, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
