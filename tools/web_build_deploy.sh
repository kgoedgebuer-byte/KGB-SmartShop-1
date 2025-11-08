#!/usr/bin/env bash
# File: tools/web_build_deploy.sh
# Build Flutter Web, serve lokaal, deploy naar GitHub Pages, open Safari & Chrome (macOS).
set -Eeuo pipefail

PROJECT_DEFAULT="$HOME/Desktop/Oud_SmartShop/smartshoplist_v140"
PROJECT="${PROJECT:-$PROJECT_DEFAULT}"
PORT="${PORT:-8080}"
RENDERER="${RENDERER:-html}"              # html | canvaskit (indien ondersteund)
DEPLOY_TARGET="${DEPLOY_TARGET:-gh-pages}" # gh-pages | docs
OPEN_LOCAL="${OPEN_LOCAL:-1}"
OPEN_GHPAGES="${OPEN_GHPAGES:-1}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN:-}"
BROWSERS="${BROWSERS:-chrome,safari}"

log(){ printf "▶ %s\n" "$*"; }
die(){ printf "✖ %s\n" "$*" >&2; exit 1; }
require(){ command -v "$1" >/dev/null 2>&1 || die "Benodigde tool ontbreekt: $1"; }

abs_path(){ python3 - "$1" <<'PY'
import os,sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

parse_remote() {
  local remote url
  remote="$(git -C "$PROJECT" remote 2>/dev/null | head -n1 || true)"
  [[ -z "$remote" ]] && die "Geen git remote gevonden in $PROJECT (voeg bv. 'origin' toe)."
  url="$(git -C "$PROJECT" remote get-url "$remote")"
  if [[ "$url" =~ ^git@([^:]+):([^/]+)/([^/]+)\.git$ ]]; then
    REPO_HOST="${BASH_REMATCH[1]}"; REPO_USER="${BASH_REMATCH[2]}"; REPO_NAME="${BASH_REMATCH[3]}"
  elif [[ "$url" =~ ^https?://([^/]+)/([^/]+)/([^/]+)(\.git)?$ ]]; then
    REPO_HOST="${BASH_REMATCH[1]}"; REPO_USER="${BASH_REMATCH[2]}"; REPO_NAME="${BASH_REMATCH[3]}"
  else
    die "Onbekend git remote formaat: $url"
  fi
}

is_user_site_repo(){ [[ "$REPO_HOST" == "github.com" && "$REPO_NAME" == "${REPO_USER}.github.io" ]]; }

ensure_flutter_web_enabled(){ log "Flutter web inschakelen…"; flutter config --enable-web >/dev/null || true; flutter --version || true; }

ensure_web_sources(){
  if [[ ! -f "$PROJECT/web/index.html" ]]; then
    log "web/ ontbreekt → 'flutter create .'"; (cd "$PROJECT" && flutter create .)
  fi
}

supports_flag() {
  local flag="$1"
  flutter build web -h 2>&1 | grep -q -- "$flag"
}

flutter_build_web(){
  local base_href="/"
  if [[ -n "$CUSTOM_DOMAIN" ]]; then base_href="/";
  elif [[ "$DEPLOY_TARGET" == "gh-pages" && ! is_user_site_repo ]]; then base_href="/${REPO_NAME}/"; fi

  local cmd=(flutter build web --release --base-href "$base_href")
  if supports_flag "--web-renderer"; then
    cmd+=("--web-renderer" "$RENDERER")
  else
    log "Let op: jouw Flutter ondersteunt '--web-renderer' niet → flag wordt overgeslagen."
  fi

  log "Build: ${cmd[*]}"
  (cd "$PROJECT" && flutter pub get && "${cmd[@]}")
  [[ -f "$PROJECT/build/web/index.html" ]] || die "Geen build/web/index.html na build."
}

start_local_server(){
  local dir="$PROJECT/build/web"
  [[ -d "$dir" ]] || die "Map ontbreekt: $dir"
  require python3; require curl
  log "Start lokale server op http://127.0.0.1:$PORT …"
  if python3 - <<'PY' >/dev/null 2>&1; then
import http.server, argparse
PY
    (python3 -m http.server "$PORT" --directory "$dir" >/tmp/web_${PORT}.log 2>&1 & echo $! > /tmp/web_${PORT}.pid)
  else
    (cd "$dir" && python3 -m http.server "$PORT" >/tmp/web_${PORT}.log 2>&1 & echo $! > /tmp/web_${PORT}.pid)
  fi
  for i in {1..50}; do curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1 && break || sleep 0.1; done
  log "Server draait (PID $(cat /tmp/web_${PORT}.pid))."
}

stop_local_server(){
  if [[ -f "/tmp/web_${PORT}.pid" ]]; then
    kill "$(cat /tmp/web_${PORT}.pid)" >/dev/null 2>&1 || true
    rm -f "/tmp/web_${PORT}.pid"
  fi
}

open_in_safari(){
  local url="$1"
  /usr/bin/osascript <<OSA >/dev/null 2>&1 || open -a "Safari" "$url"
try
  tell application "Safari"
    if it is running then
      if (count of windows) = 0 then make new document
      tell window 1 to set current tab to (make new tab with properties {URL:"$url"})
      activate
    else
      open location "$url"
      activate
    end if
  end tell
end try
OSA
}

open_in_chrome(){
  local url="$1"
  /usr/bin/osascript <<OSA >/dev/null 2>&1 || open -a "Google Chrome" "$url"
try
  tell application "Google Chrome"
    if it is running then
      if (count of windows) = 0 then make new window
      tell window 1 to make new tab with properties {URL:"$url"}
      activate
    else
      open location "$url"
      activate
    end if
  end tell
end try
OSA
}

open_browsers(){
  local url="$1"
  IFS=',' read -ra arr <<< "$BROWSERS"
  for b in "${arr[@]}"; do
    case "$b" in
      safari) log "Open Safari: $url"; open_in_safari "$url" ;;
      chrome) log "Open Chrome: $url"; open_in_chrome "$url" ;;
    esac
  done
}

deploy_to_gh_pages(){
  require rsync
  log "Deploy naar gh-pages (git worktree)…"
  (cd "$PROJECT" && git fetch origin --prune || true)
  if ! git -C "$PROJECT" show-ref --verify --quiet refs/heads/gh-pages; then
    (cd "$PROJECT" && git checkout --orphan gh-pages && git reset --hard \
      && echo "# gh-pages" > README.md && git add README.md \
      && git commit -m "init gh-pages" && git push -u origin gh-pages && git checkout -)
  fi
  rm -rf "$PROJECT/.gh-pages"
  git -C "$PROJECT" worktree add -f "$PROJECT/.gh-pages" gh-pages
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/.gh-pages/"
  [[ -n "$CUSTOM_DOMAIN" ]] && echo "$CUSTOM_DOMAIN" > "$PROJECT/.gh-pages/CNAME"
  touch "$PROJECT/.gh-pages/.nojekyll"
  (cd "$PROJECT/.gh-pages" && git add -A && git commit -m "Deploy $(date -u +%F_%T)" || true && git push origin gh-pages)
  if [[ -n "$CUSTOM_DOMAIN" ]]; then PAGES_URL="https://${CUSTOM_DOMAIN}/";
  elif is_user_site_repo; then PAGES_URL="https://${REPO_USER}.github.io/";
  else PAGES_URL="https://${REPO_USER}.github.io/${REPO_NAME}/"; fi
  log "GH Pages: $PAGES_URL"
}

deploy_to_docs(){
  require rsync
  log "Deploy naar /docs op main…"
  mkdir -p "$PROJECT/docs"
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/docs/"
  (cd "$PROJECT" && git add docs && git commit -m "Update docs $(date -u +%F_%T)" || true && git push)
  if [[ -n "$CUSTOM_DOMAIN" ]]; then PAGES_URL="https://${CUSTOM_DOMAIN}/";
  elif is_user_site_repo; then PAGES_URL="https://${REPO_USER}.github.io/";
  else PAGES_URL="https://${REPO_USER}.github.io/${REPO_NAME}/"; fi
  log "GH Pages: $PAGES_URL (zet Pages source op main/docs)"
}

usage(){ cat <<USAGE
$(basename "$0") --project PATH [--port N] [--renderer html|canvaskit] [--target gh-pages|docs]
                 [--no-open-local] [--no-open-pages] [--browsers chrome,safari] [--custom-domain HOST]
USAGE
}

# --- CLI parse ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) shift; PROJECT="$(abs_path "${1:-}")";;
    --port) shift; PORT="${1:-8080}";;
    --renderer) shift; RENDERER="${1:-html}";;
    --target) shift; DEPLOY_TARGET="${1:-gh-pages}";;
    --no-open-local) OPEN_LOCAL=0;;
    --no-open-pages) OPEN_GHPAGES=0;;
    --browsers) shift; BROWSERS="${1:-chrome,safari}";;
    --custom-domain) shift; CUSTOM_DOMAIN="${1:-}";;
    -h|--help) usage; exit 0;;
    *) die "Onbekende optie: $1";;
  esac; shift || true
done

# --- Checks & flow ---
require git; require flutter; require python3; require curl
[[ -d "$PROJECT" ]] || die "Projectpad bestaat niet: $PROJECT"

trap 'stop_local_server' EXIT

parse_remote
ensure_flutter_web_enabled
ensure_web_sources
flutter_build_web

LOCAL_URL="http://127.0.0.1:${PORT}/"
if [[ "$OPEN_LOCAL" == "1" ]]; then
  start_local_server
  open_browsers "$LOCAL_URL"
fi

case "$DEPLOY_TARGET" in
  gh-pages) deploy_to_gh_pages ;;
  docs)     deploy_to_docs ;;
esac

if [[ "$OPEN_GHPAGES" == "1" && -n "${PAGES_URL:-}" ]]; then
  open_browsers "$PAGES_URL"
fi

log "Klaar."
