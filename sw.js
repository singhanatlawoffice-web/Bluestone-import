/* Service worker ของ Blue Stone Import
   เก็บหน้าเว็บไว้ในเครื่องเพื่อให้เปิดใช้งานได้แม้สัญญาณขาด
   ข้อมูลที่ซิงก์กับ Supabase ไม่ถูกแคช เพื่อให้ได้ของล่าสุดเสมอ */
var CACHE = 'bluestone-import-v3';
var SHELL = [
  './',
  './index.html',
  './login.html',
  './board.html',
  './photos.html',
  './d.html',
  './config.js',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/apple-touch-icon.png'
];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) {
    return Promise.all(SHELL.map(function (u) {
      return c.add(u).catch(function () { /* ไฟล์ไหนโหลดไม่ได้ก็ข้ามไป */ });
    }));
  }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (ks) {
    return Promise.all(ks.map(function (k) { return k === CACHE ? null : caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') { return; }
  var url = new URL(req.url);
  if (url.origin !== self.location.origin) { return; }      /* Supabase และ CDN ไม่แคช */
  e.respondWith(
    fetch(req).then(function (res) {
      var copy = res.clone();
      caches.open(CACHE).then(function (c) { c.put(req, copy); });
      return res;
    }).catch(function () {
      return caches.match(req).then(function (hit) {
        return hit || caches.match('./index.html');
      });
    })
  );
});
