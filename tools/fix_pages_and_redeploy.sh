#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="${PROJECT:-$HOME/Desktop/Oud_SmartShop/smartshoplist_v140}"
VERSION="${VERSION:-v$(date +%Y%m%d%H%M%S)}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
need git; need flutter; need python3; need rsync; need curl

# 1) Altijd op main
git fetch origin --prune >/dev/null 2>&1 || true
git rev-parse --abbrev-ref HEAD | grep -qx main || { echo "▶ switch naar main"; git switch main 2>/dev/null || git checkout -B main; }

# 2) Owner/Repo + base + URL
read OWNER REPO <<EOF
$(python3 - <<'PY'
import subprocess, urllib.parse
u=subprocess.check_output(['git','remote','get-url','origin']).decode().strip()
if u.startswith('git@'):
  owner,repo=u.split(':',1)[1].split('/',1)
else:
  p=urllib.parse.urlparse(u); owner,repo=p.path.lstrip('/').split('/',1)
if repo.endswith('.git'): repo=repo[:-4]
print(owner,repo)
PY
)
EOF
if [[ "$REPO" == "${OWNER}.github.io" ]]; then
  BASE="/${VERSION}/"; ROOT_URL="https://${OWNER}.github.io/"; URL="${ROOT_URL}${VERSION}/"
else
  BASE="/${REPO}/${VERSION}/"; ROOT_URL="https://${OWNER}.github.io/${REPO}/"; URL="${ROOT_URL}${VERSION}/"
fi

echo "▶ Build naar: $URL (base-href: $BASE)"
(
  cd "$PROJECT"
  flutter config --enable-web >/dev/null || true
  flutter clean
  flutter pub get
  flutter build web --release --base-href "$BASE"
)

# 3) SW uit + manifest weg + cache-bust
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
extra="<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations().then(function(rs){rs.forEach(function(r){try{r.unregister()}catch(e){}})})}if(window.caches&&caches.keys){caches.keys().then(function(k){k.forEach(function(x){caches.delete(x)})})}}catch(e){}})();</script>"
s=re.sub(r"</body>", extra+"</body>", s, flags=re.I)
open(p,"w",encoding="utf-8").write(s)
for fn in ("flutter_service_worker.js","firebase-messaging-sw.js"):
  fp=os.path.join(d,fn)
  if os.path.exists(fp):
    try: os.remove(fp)
    except: pass
PY

# 4) Deploy naar docs/VERSION en root-redirect
DEST="$PROJECT/docs/${VERSION}"
mkdir -p "$DEST"
rsync -a --delete "$PROJECT/build/web/" "$DEST/"
echo "${VERSION}" > "$PROJECT/docs/version.txt"
cat > "$PROJECT/docs/index.html" <<HTML
<!doctype html><meta http-equiv="refresh" content="0; url=./${VERSION}/"><meta name="robots" content="noindex"><title>Redirect</title>
<a href="./${VERSION}/">Doorgaan…</a>
HTML

# 5) Commit + push naar main
(
  cd "$PROJECT"
  git add docs
  git commit -m "docs: ${VERSION}" || true
  git push -u origin main
)

# 6) Forceer GitHub Pages → main/docs (als 'gh' aanwezig is)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "▶ Pages bron zetten op main/docs…"
  gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 || true
else
  echo "ℹ Tip: zet in GitHub ▸ Settings ▸ Pages ▸ Source: main /docs"
fi

# 7) Health-check (wacht tot 200)
echo "▶ Health-check (max 60s)…"
ok=0
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
  if [ "$code" = "200" ]; then ok=1; break; fi
  sleep 1
done
[ "$ok" = "1" ] && echo "✅ Live: $URL" || echo "⚠ Nog niet 200 (probeer de link alsnog)."

# 8) Open in browsers met cache-buster
ts=$(date +%s); open -a "Safari"        "${URL}?ts=${ts}" 2>/dev/null || true
ts=$(date +%s); open -a "Google Chrome" "${URL}?ts=${ts}" 2>/dev/null || true

echo "Klaar. Versie-URL: $URL  (root redirect: $ROOT_URL)"
