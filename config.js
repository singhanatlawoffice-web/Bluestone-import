/* ------------------------------------------------------------------
   ค่าเชื่อมต่อของ Blue Stone Import

   แก้เฉพาะในบล็อก window.BS_CONFIG ด้านล่างเท่านั้น
   อย่าแก้ในส่วนคำอธิบายนี้ เพราะเป็นคอมเมนต์ ระบบไม่อ่าน

     url   Project URL ของ Supabase
     key   Publishable key (ขึ้นต้น sb_publishable_) หรือ anon public key
           ห้ามใส่ secret key หรือ service_role เด็ดขาด
     site  ที่อยู่เว็บจริง ใช้สร้างลิงก์ส่งรูปที่ส่งให้พนักงานขับรถ
           ถ้าเปลี่ยนชื่อเว็บบน Vercel ต้องแก้บรรทัดนี้ให้ตรงแล้ว push ใหม่

   คีย์ publishable เป็นคีย์ฝั่งผู้ใช้ เปิดเผยได้ตามปกติของ Supabase
   สิ่งที่กันคนนอกจริง ๆ คือ Row Level Security ในไฟล์ supabase/schema-auth.sql
------------------------------------------------------------------- */
window.BS_CONFIG = {
  url: 'https://eoirzsvknmnjgsuvwzjz.supabase.co',
  key: 'sb_publishable_BoWr-6aB_Uz8IExwf6Zp1Q_le7FQQjH',
  site: 'https://bluestone-import.vercel.app'
};
