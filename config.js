/* ------------------------------------------------------------------
   ค่าเชื่อมต่อ Supabase ของ Blue Stone Import

   ใส่ค่าจาก Supabase > Project Settings > API
     url : Project URL        เช่น https://xxxxxxxx.supabase.co
     key : anon public key    (ห้ามใส่ service_role key เด็ดขาด)

   anon key เป็นคีย์ฝั่งผู้ใช้ ออกแบบมาให้เปิดเผยได้ตามปกติของ Supabase
   ความปลอดภัยจริงอยู่ที่ Row Level Security ในไฟล์ supabase/schema.sql

   เว้นว่างไว้ได้ ระบบจะทำงานแบบเก็บข้อมูลในเครื่องเดียว
   และกรอกค่าจากหน้าตั้งค่าอัตราในเว็บแทนก็ได้

   site : ที่อยู่เว็บจริงหลัง deploy ใช้สร้างลิงก์ส่งรูปที่ส่งให้คนขับ
          ถ้า Vercel ให้ชื่ออื่น ต้องแก้ตรงนี้ให้ตรง ไม่งั้นลิงก์ในข้อความจะเปิดไม่ได้
------------------------------------------------------------------- */
window.BS_CONFIG = {
  url: 'https://eoirzsvknmnjgsuvwzjz.supabase.co',
  key: '',
  site: 'https://bluestone-import.vercel.app'
};
