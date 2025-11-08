#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="${PROJECT:-$HOME/Desktop/Oud_SmartShop/smartshoplist_v140}"
VERSION="${VERSION:-v$(date +%Y%m%d%H%M%S)}"
PWA="${PWA:-0}"  # 0 = geen PWA, 1 = PWA aan

need(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
need git; need flutter; need python3; need rsync; need curl

# Altijd op main
git fetch origin --prune >/dev/null 2>&1 || true
git rev-parse --abbrev-ref HEAD | grep -qx main || { git switch main 2>/dev/null || git checkout -B main; }

# OWNER/REPO
read OWNER REPO <<EOF
$(python3 - <<'PY'
import subprocess, urllib.parse
u=subprocess.check_output(['git','remote','get-url','origin']).decode().strip()
if u.startswith('git@'): o,r=u.split(':',1)[1].split('/',1)
else:
  p=urllib.parse.urlparse(u); o,r=p.path.lstrip('/').split('/',1)
if r.endswith('.git'): r=r[:-4]
print(o,r)
PY
)
EOF

# Base/URL
if [[ "$REPO" == "${OWNER}.github.io" ]]; then
  BASE="/${VERSION}/"; ROOT="https://${OWNER}.github.io/"; URL="${ROOT}${VERSION}/"
else
  BASE="/${REPO}/${VERSION}/"; ROOT="https://${OWNER}.github.io/${REPO}/"; URL="${ROOT}${VERSION}/"
fi

echo "▶ Build: base-href=${BASE}  PWA=${PWA}  → ${URL}"
(
  cd "$PROJECT"
  flutter config --enable-web >/dev/null || true
  flutter clean
  flutter pub get
  flutter build web --release --base-href "$BASE"
)

# Postprocess: SW/manifest afhankelijk van PWA
python3 - "$PROJECT/build/web" "$PWA" "$VERSION" <<'PY'
import os,re,time,sys,json
d=sys.argv[1]; pwa = sys.argv[2]=='1'; ver=sys.argv[3]
p=os.path.join(d,"index.html")
s=open(p,"r",encoding="utf-8").read()

def rm_manifest(html):
  return re.sub(r'\s*<link[^>]*rel=["\']manifest["\'][^>]*>\s*','',html,flags=re.I)

def add_manifest(html):
  if re.search(r'rel=["\']manifest["\']', html, flags=re.I): return html
  head_end = re.search(r'</head>', html, flags=re.I)
  if not head_end: return html
  link = '<link rel="manifest" href="manifest.json">\n'
  # iOS meta (A2HS)
  ios = '<meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="default">'
  return html[:head_end.start()] + link + ios + html[head_end.start():]

# Cache-bust van bootstrap en runtime js
ts=str(int(time.time()))
s=s.replace('src="flutter.js"', f'src="flutter.js?v={ts}"')
s=s.replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={ts}"')

if pwa:
  # Zet Flutter SW uit, wij registreren onze eigen
  s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
  s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
  s=add_manifest(s)
  reg = """
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('./service-worker.js', {scope:'./'}).catch(console.warn);
  });
}
</script>"""
  s = re.sub(r"</body>", reg+"</body>", s, flags=re.I)
  open(p,"w",encoding="utf-8").write(s)

  # Schrijf manifest.json (gebruik bestaande iconen als ze er zijn)
  icons=[]
  for sz in (192,512):
    fn=f'icons/Icon-{sz}.png'
    if os.path.exists(os.path.join(d,fn)):
      icons.append({"src": fn, "sizes": f"{sz}x{sz}", "type":"image/png"})
  man = {
    "name":"KGB SmartShop",
    "short_name":"SmartShop",
    "start_url":"./",
    "scope":"./",
    "display":"standalone",
    "background_color":"#ffffff",
    "theme_color":"#1976d2",
    "icons": icons
  }
  open(os.path.join(d,"manifest.json"),"w",encoding="utf-8").write(json.dumps(man,ensure_ascii=False,indent=2))

  # Schrijf onze service-worker op basis van template
  tpl = open(os.path.join(os.path.dirname(__file__),'pwa_sw.js.tpl'),encoding='utf-8').read()
  open(os.path.join(d,"service-worker.js"),"w",encoding="utf-8").write(tpl.replace('__APP_VERSION__',ver))
else:
  # Geen PWA: alle SW/manifest weghalen en bestaande SW's afmelden bij load
  s=rm_manifest(s)
  s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
  s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
  unreg = "<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations().then(r=>r.forEach(x=>x.unregister()));}if(window.caches&&caches.keys){caches.keys().then(k=>k.forEach(x=>caches.delete(x)));}}catch(e){}})();</script>"
  s=re.sub(r"</body>", unreg+"</body>", s, flags=re.I)
  open(p,"w",encoding="utf-8").write(s)
  for fn in ("flutter_service_worker.js","firebase-messaging-sw.js","manifest.json","service-worker.js"):
    fp=os.path.join(d,fn)
    if os.path.exists(fp):
      try: os.remove(fp)
      except: pass
PY

# Deploy naar docs/VERSION + root redirect
DEST="$PROJECT/docs/${VERSION}"
mkdir -p "$DEST"
rsync -a --delete "$PROJECT/build/web/" "$DEST/"
echo "${VERSION}" > "$PROJECT/docs/version.txt"
cat > "$PROJECT/docs/index.html" <<HTML
<!doctype html><meta http-equiv="refresh" content="0; url=./${VERSION}/"><meta name="robots" content="noindex"><title>Redirect</title>
<a href="./${VERSION}/">Doorgaan…</a>
HTML

(
  cd "$PROJECT"
  git add docs
  git commit -m "docs(versioned): ${VERSION} (PWA=${PWA})" || true
  git push -u origin main
)

# Pages naar main/docs (best effort)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 || true
fi

# Openen met cache-buster
ts=$(date +%s)
open -a "Safari"        "${URL}?ts=${ts}" 2>/dev/null || true
open -a "Google Chrome" "${URL}?ts=${ts}" 2>/dev/null || true
echo "✅ Live: ${URL}   (root: ${ROOT})"
