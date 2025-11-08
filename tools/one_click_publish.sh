#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="${PROJECT:-$PWD}"
VERSION="${VERSION:-v$(date +%Y%m%d%H%M%S)}"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
need git; need python3; need curl; need rsync
command -v flutter >/dev/null 2>&1 || { echo "✖ flutter ontbreekt"; exit 1; }

# --- OWNER/REPO ---
remote="$(git -C "$PROJECT" remote get-url origin)"
read OWNER REPO <<EOF
$(python3 - "$remote" <<'PY'
import sys,urllib.parse
u=sys.argv[1].strip(); o=r=""
if u.startswith("git@"): o,r=u.split(":",1)[1].split("/",1)
else:
  p=urllib.parse.urlparse(u); o,r=p.path.lstrip("/").split("/",1)
if r.endswith(".git"): r=r[:-4]
print(o,r)
PY
)
EOF
[ -n "$OWNER" ] && [ -n "$REPO" ] || { echo "✖ Geen geldige git remote"; exit 1; }

# --- URLs / base-href ---
if [[ "$REPO" == "${OWNER}.github.io" ]]; then
  BASE="/${VERSION}/"; ROOT="https://${OWNER}.github.io/"; URL="${ROOT}${VERSION}/"
else
  BASE="/${REPO}/${VERSION}/"; ROOT="https://${OWNER}.github.io/${REPO}/"; URL="${ROOT}${VERSION}/"
fi

# --- Altijd op main werken ---
git -C "$PROJECT" fetch origin --prune >/dev/null 2>&1 || true
branch="$(git -C "$PROJECT" rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  git -C "$PROJECT" switch main 2>/dev/null || git -C "$PROJECT" checkout -B main
fi

# --- Build (Flutter web) ---
echo "▶ Build: base-href=${BASE}"
(
  cd "$PROJECT"
  flutter config --enable-web >/dev/null || true
  flutter clean
  flutter pub get
  flutter build web --release --base-href "$BASE"
)

# --- Postprocess: SW UIT + manifest weg + cache-bust ---
python3 - "$PROJECT/build/web" <<'PY'
import os,re,time,sys
d=sys.argv[1]; p=os.path.join(d,"index.html")
s=open(p,"r",encoding="utf-8").read()
# Zet Flutter SW uit
s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
# Verwijder manifest-link (geen “Installeren” nu)
s=re.sub(r'\s*<link[^>]*rel=["\']manifest["\'][^>]*>\s*','',s,flags=re.I)
# Cache-bust
ts=str(int(time.time()))
s=s.replace('src="flutter.js"', f'src="flutter.js?v={ts}"')
s=s.replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={ts}"')
# Unregister oude SW + caches leeg
extra="<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations().then(r=>r.forEach(x=>x.unregister()));}if(window.caches&&caches.keys){caches.keys().then(k=>k.forEach(x=>caches.delete(x)));}}catch(e){}})();</script>"
s=re.sub(r"</body>", extra+"</body>", s, flags=re.I)
open(p,"w",encoding="utf-8").write(s)
for fn in ("flutter_service_worker.js","firebase-messaging-sw.js","manifest.json","service-worker.js"):
  fp=os.path.join(d,fn)
  if os.path.exists(fp):
    try: os.remove(fp)
    except: pass
PY

# --- Deploy naar docs/<VERSION>/ + root redirect ---
DEST="$PROJECT/docs/${VERSION}"
mkdir -p "$DEST"
rsync -a --delete "$PROJECT/build/web/" "$DEST/"
echo "${VERSION}" > "$PROJECT/docs/version.txt"
cat > "$PROJECT/docs/index.html" <<HTML
<!doctype html><meta http-equiv="refresh" content="0; url=./${VERSION}/"><meta name="robots" content="noindex"><title>Redirect</title>
<a href="./${VERSION}/">Doorgaan…</a>
HTML

# --- Commit & push ---
(
  cd "$PROJECT"
  git add docs
  git commit -m "docs(versioned): ${VERSION}" || true
  git push -u origin main
)

# --- Forceer Pages → main/docs (indien gh beschikbaar) ---
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "▶ Pages naar main/docs…"
  gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 || true
else
  echo "ℹ Zet 1× in GitHub: Settings ▸ Pages ▸ Source: main /docs ▸ Save"
fi

# --- Health-check + open ---
echo "▶ Health-check:"
for p in "" "index.html" "main.dart.js" "assets/AssetManifest.json"; do
  code="$(curl -s -o /dev/null -w '%{http_code}' "${URL}${p}")"
  printf "  %-28s -> %s\n" "${p:-/}" "$code"
done

ts=$(date +%s)
open -a "Safari"        "${URL}?ts=${ts}" 2>/dev/null || true
open -a "Google Chrome" "${URL}?ts=${ts}" 2>/dev/null || true

echo "✅ Deel-link (root → laatste versie): ${ROOT}"
echo "   Versie-URL: ${URL}"
