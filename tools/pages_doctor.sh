#!/usr/bin/env bash
set -Eeuo pipefail
req(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
req git; req python3; req curl
remote="$(git remote get-url origin)"
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
[[ "$REPO" == "${OWNER}.github.io" ]] && URL="https://${OWNER}.github.io/" || URL="https://${OWNER}.github.io/${REPO}/"
echo "URL: $URL"
curl -Is "$URL" | sed -n '1,20p'
curl -s "$URL" | grep -Eo 'main\.dart\.js[^"]*' | head -n1 || echo "main.dart.js niet gevonden in HTML"
echo "Openen…"; open -a "Safari" "$URL?ts=$(date +%s)" 2>/dev/null || true; open -a "Google Chrome" "$URL?ts=$(date +%s)" 2>/dev/null || true
