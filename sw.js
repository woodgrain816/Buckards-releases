/* Buckards offline worker (GitHub Pages copy only).
   The whole game is one page, so once it is saved here the game runs with no
   internet at all. Online, the page is always fetched fresh (and re-saved), so
   updates still arrive; offline, or on a connection that stalls, the saved copy
   is served instead. */
const CACHE = 'buckards-offline-v1';
const CORE = ['./', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET' || new URL(r.url).origin !== location.origin) return;   // update checks etc. just fail offline
  if (r.mode === 'navigate') {
    const net = fetch(r, { cache: 'no-store' }).then(res => {
      if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put('./', copy)); }
      return res;
    });
    const slow = new Promise(ok => setTimeout(ok, 4000)).then(() => caches.match('./'));
    e.respondWith(Promise.race([net.catch(() => caches.match('./')), slow.then(hit => hit || net)]));
    return;
  }
  e.respondWith(caches.match(r).then(hit => hit || fetch(r)));
});
