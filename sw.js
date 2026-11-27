// Сервис-воркер «Поиск кадров»: оболочка сайта работает офлайн, данные (Supabase, TMDB API) всегда берутся из сети, постеры TMDB кэшируются для скорости.
const C = "kadry-v3", IMGC = "kadry-img", SHELL = ["./", "index.html", "manifest.webmanifest", "icon-192.png", "icon-512.png", "apple-touch-icon.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(C).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(k => Promise.all(k.filter(x => x !== C && x !== IMGC).map(x => caches.delete(x)))).then(() => self.clients.claim())); });
const trim = async c => { const k = await c.keys(); if (k.length > 500) await c.delete(k[0]); };
self.addEventListener("fetch", e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== "GET") return;
  if (u.origin !== location.origin) {
    if (u.hostname === "image.tmdb.org") {
      e.respondWith(caches.open(IMGC).then(c => c.match(r).then(hit => hit || fetch(r).then(res => {
        if (res.ok || res.type === "opaque") { c.put(r, res.clone()).then(() => trim(c)); }
        return res;
      }))));
    }
    return;
  }
  e.respondWith(fetch(r).then(res => { const cp = res.clone(); caches.open(C).then(c => c.put(r, cp)); return res; })
    .catch(() => caches.match(r).then(x => x || caches.match("index.html"))));
});
