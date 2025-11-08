// tools/pwa_sw.js.tpl
// Veilig SW: index.html niet hard cachen, assets wel. Direct updaten.
const VERSION = '__APP_VERSION__';
const CACHE = 'smartshop-' + VERSION;

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil((async () => {
    const toCache = ['flutter.js','flutter_bootstrap.js','main.dart.js'];
    try {
      const res = await fetch('assets/AssetManifest.json', {cache:'no-store'});
      const assets = Object.keys(await res.json());
      toCache.push(...assets);
    } catch (_) {}
    const cache = await caches.open(CACHE);
    await cache.addAll(toCache.map(u => new Request(u, {cache:'no-store'})));
  })());
});

self.addEventListener('activate', (e) => {
  self.clients.claim();
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)));
  })());
});

// Navigatie: probeer netwerk eerst (nieuwe index), fallback offline index
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).catch(() => caches.match('index.html')));
    return;
  }
  e.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    try { return await fetch(req); } catch { return cached; }
  })());
});
