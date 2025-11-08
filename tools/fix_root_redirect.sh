#!/usr/bin/env bash
set -Eeuo pipefail

need(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ $1 ontbreekt"; exit 1; }; }
need git
OWNER="$(git remote get-url origin | python3 - <<'PY'
import sys,urllib.parse
u=sys.stdin.read().strip()
if u.startswith("git@"): print(u.split(":",1)[1].split("/",1)[0])
else: print(urllib.parse.urlparse(u).path.lstrip("/").split("/",1)[0])
PY
)"
REPO_TARGET="KGB-SmartShop-1"
USER_REPO="${OWNER}.github.io"
ROOT_URL="https://${OWNER}.github.io/"
TARGET_URL="${ROOT_URL}${REPO_TARGET}/"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  # bestaat usersite-repo? zo niet: maak hem
  if ! gh repo view "${OWNER}/${USER_REPO}" >/dev/null 2>&1; then
    echo "▶ Maak usersite-repo ${USER_REPO}…"
    gh repo create "${OWNER}/${USER_REPO}" --public -y >/dev/null
  fi
  # clone werkdir
  tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
  git clone "https://github.com/${OWNER}/${USER_REPO}.git" "$tmpdir/${USER_REPO}" >/dev/null 2>&1 || \
  git clone "git@github.com:${OWNER}/${USER_REPO}.git" "$tmpdir/${USER_REPO}" >/dev/null
  cd "$tmpdir/${USER_REPO}"

  # index + 404 met redirect → project
  cat > index.html <<HTML
<!doctype html><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=${TARGET_URL}">
<title>Doorsturen…</title>
<a href="${TARGET_URL}">Doorgaan naar KGB SmartShop</a>
HTML
  cp index.html 404.html

  git add -A
  git commit -m "chore: redirect root -> ${REPO_TARGET}/" >/dev/null || true
  git push -u origin main >/dev/null 2>&1 || { git branch -M main && git push -u origin main >/dev/null; }

  # Pages voor usersite = main/(root)
  echo "▶ Usersite Pages → main /(root)…"
  gh api -X PUT "repos/${OWNER}/${USER_REPO}/pages" -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true

  # open
  ts=$(date +%s)
  echo "✅ Root redirect actief: ${ROOT_URL} → ${TARGET_URL}"
  open -a "Safari"        "${ROOT_URL}?ts=$ts" 2>/dev/null || true
  open -a "Google Chrome" "${ROOT_URL}?ts=$ts" 2>/dev/null || true
else
  echo "ℹ gh CLI niet ingelogd. Snelste handmatige stappen:"
  echo "  1) Maak (of open) repo: https://github.com/${OWNER}/${USER_REPO}"
  echo "  2) Voeg in de root een index.html met dit inhalt (redirect):"
  echo "     <!doctype html><meta http-equiv=\"refresh\" content=\"0; url=${TARGET_URL}\"><title>Redirect</title>"
  echo "  3) GitHub ▸ Settings ▸ Pages ▸ Source: main / (root) ▸ Save"
  echo "  4) Open ${ROOT_URL} (zou doorsturen naar ${TARGET_URL})"
  exit 0
fi
