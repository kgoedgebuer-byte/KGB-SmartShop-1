#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT="${PROJECT:-$PWD}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
need git; need flutter; need python3; need rsync; need curl

# Parse owner/repo (https of ssh)
remote="$(git -C "$PROJECT" remote get-url origin)"
read OWNER REPO <<EOF
$(python3 - "$remote" <<'PY'
import sys,urllib.parse
u=sys.argv[1].strip()
if u.startswith("git@"):
  o,r=u.split(":",1)[1].split("/",1)
else:
  p=urllib.parse.urlparse(u); o,r=p.path.lstrip("/").split("/",1)
if r.endswith(".git"): r=r[:-4]
print(o,r)
PY
)
EOF

# Pages-URL en base-href
if [[ "$REPO" == "${OWNER}.github.io" ]]; then BASE="/"; URL="https://${OWNER}.github.io/"; else BASE="/${REPO}/"; URL="https://${OWNER}.github.io/${REPO}/"; fi

echo "▶ Build → base-href=${BASE}"
(
  cd "$PROJECT"
  flutter config --enable-web >/dev/null || true
  flutter clean
  flutter pub get
  flutter build web --release --base-href "$BASE"
)

# SW uit + manifest weg + cache-bust + unregister
python3 - "$PROJECT/build/web" <<'PY'
import os,re,time,sys
d=sys.argv[1]; p=os.path.join(d,"index.html")
s=open(p,"r",encoding="utf-8").read()
s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
s=re.sub(r'\s*<link[^>]*rel=["\']manifest["\'][^>]*>\s*','',s,flags=re.I)
ts=str(int(time.time()))
s=s.replace('src="flutter.js"', f'src="flutter.js?v={ts}"')
s=s.replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={ts}"')
unreg="<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations().then(r=>r.forEach(x=>x.unregister()));}if(window.caches&&caches.keys){caches.keys().then(k=>k.forEach(x=>caches.delete(x)));}}catch(e){}})();</script>"
s=re.sub(r"</body>", unreg+"</body>", s, flags=re.I)
open(p,"w",encoding="utf-8").write(s)
for fn in ("flutter_service_worker.js","firebase-messaging-sw.js","manifest.json","service-worker.js"):
  fp=os.path.join(d,fn)
  if os.path.exists(fp):
    try: os.remove(fp)
    except: pass
PY

# Deploy naar main/docs (branch-based Pages)
echo "▶ Deploy → main/docs"
mkdir -p "$PROJECT/docs"
rsync -a --delete "$PROJECT/build/web/" "$PROJECT/docs/"
echo "$(date +v%Y%m%d%H%M%S)" > "$PROJECT/docs/version.txt"

(
  cd "$PROJECT"
  git add docs
  git commit -m "docs: deploy $(date -u +%F_%T)" || true
  git push
)

# Herinnering: Settings ▸ Pages ▸ Source = main /docs
echo "▶ Zorg dat GitHub Pages op: main  /docs staat."
echo "▶ Health-check:"
for p in "" "index.html" "main.dart.js" "assets/AssetManifest.json"; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "${URL}${p}")"
  printf "  %-28s -> %s\n" "${p:-/}" "$code"
done

ts=$(date +%s)
open -a "Google Chrome" "${URL}?ts=${ts}" 2>/dev/null || true
open -a "Safari"        "${URL}?ts=${ts}" 2>/dev/null || true
echo "✅ Deel: ${URL}"
