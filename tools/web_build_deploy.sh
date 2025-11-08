#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DEFAULT="$HOME/Desktop/Oud_SmartShop/smartshoplist_v140"
PROJECT="${PROJECT:-$PROJECT_DEFAULT}"
PORT="${PORT:-8080}"
RENDERER="${RENDERER:-html}"
BROWSERS="${BROWSERS:-chrome,safari}"
OPEN_LOCAL="${OPEN_LOCAL:-0}"
OPEN_GHPAGES="${OPEN_GHPAGES:-1}"
TARGET="${TARGET:-auto}" # auto|gh-pages|docs

log(){ printf "▶ %s\n" "$*"; }
die(){ printf "✖ %s\n" "$*" >&2; exit 1; }
require(){ command -v "$1" >/dev/null 2>&1 || die "Tool ontbreekt: $1"; }

abs(){ python3 - "$1" <<'PY'
import os,sys; print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
}

supports_flag(){ flutter build web -h 2>&1 | grep -q -- "$1"; }

git_parse_remote(){
  local url; url="$(git -C "$PROJECT" remote get-url origin)"
  read OWNER REPO <<EOF
$(python3 - "$url" <<'PY'
import sys, urllib.parse
u = sys.argv[1].strip()
owner = repo = ""
if u.startswith("git@"):
    host_path = u.split(":",1)[1]
    owner, repo = host_path.split("/",1)
else:
    p = urllib.parse.urlparse(u)
    path = p.path.lstrip("/")
    if "/" in path:
        owner, repo = path.split("/",1)
if repo.endswith(".git"): repo = repo[:-4]
print(owner, repo)
PY
)
EOF
  [[ -n "${OWNER:-}" && -n "${REPO:-}" ]] || die "Onbekende git remote: $url"
}

is_user_site_repo(){ [[ "$REPO" == "${OWNER}.github.io" ]]; }
compute_pages_url(){ if is_user_site_repo; then PAGES_URL="https://${OWNER}.github.io/"; else PAGES_URL="https://${OWNER}.github.io/${REPO}/"; fi; }

ensure_web(){ flutter config --enable-web >/dev/null || true; [[ -f "$PROJECT/web/index.html" ]] || (cd "$PROJECT" && flutter create .); }

detect_pages_source(){
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    local json branch path
    if json="$(gh api "repos/${OWNER}/${REPO}/pages" 2>/dev/null)"; then
      branch="$(printf '%s' "$json" | python3 - <<'PY'
import sys,json; print(json.load(sys.stdin).get("source",{}).get("branch",""))
PY
)"
      path="$(printf '%s' "$json" | python3 - <<'PY'
import sys,json; print(json.load(sys.stdin).get("source",{}).get("path",""))
PY
)"
      [[ "$branch" == "gh-pages" && "$path" == "/" ]] && { echo gh-pages; return; }
      [[ "$branch" == "main" && "$path" == "/docs" ]] && { echo docs; return; }
    fi
  fi
  git -C "$PROJECT" ls-remote --heads origin gh-pages >/dev/null 2>&1 && { echo gh-pages; return; }
  echo docs
}

activate_pages(){
  local mode="$1"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if [[ "$mode" == "gh-pages" ]]; then
      gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=gh-pages" -f "source[path]=/" >/dev/null 2>&1 || true
    else
      gh api -X PUT "repos/${OWNER}/${REPO}/pages" -f "source[branch]=main" -f "source[path]=/docs" >/dev/null 2>&1 || true
    fi
  fi
}

build_web(){
  local base_href="/"; ! is_user_site_repo && base_href="/${REPO}/"
  local cmd=(flutter build web --release --base-href "$base_href")
  supports_flag "--web-renderer" && cmd+=("--web-renderer" "$RENDERER") || log "⏭  --web-renderer niet ondersteund"
  (cd "$PROJECT" && flutter pub get && "${cmd[@]}")
  [[ -f "$PROJECT/build/web/index.html" ]] || die "build/web/index.html ontbreekt"
}

open_in_safari(){ /usr/bin/osascript <<OSA >/dev/null 2>&1 || open -a "Safari" "$1"
try
  tell application "Safari"
    if it is running then
      if (count of windows) = 0 then make new document
      tell window 1 to set current tab to (make new tab with properties {URL:"$1"})
      activate
    else
      open location "$1"
      activate
    end if
  end tell
end try
OSA
}
open_in_chrome(){ /usr/bin/osascript <<OSA >/dev/null 2>&1 || open -a "Google Chrome" "$1"
try
  tell application "Google Chrome"
    if it is running then
      if (count of windows) = 0 then make new window
      tell window 1 to make new tab with properties {URL:"$1"}
      activate
    else
      open location "$1"
      activate
    end if
  end tell
end try
OSA
}
open_browsers(){ IFS=',' read -ra a <<< "$BROWSERS"; for b in "${a[@]}"; do [[ "$b" == safari ]] && open_in_safari "$1" || { [[ "$b" == chrome ]] && open_in_chrome "$1"; }; done; }

deploy_to_gh_pages(){
  require rsync
  (cd "$PROJECT" && git fetch origin --prune || true)
  git -C "$PROJECT" show-ref --verify --quiet refs/heads/gh-pages || (cd "$PROJECT" && git checkout --orphan gh-pages && git reset --hard && echo "# gh-pages" > README.md && git add README.md && git commit -m "init gh-pages" && git push -u origin gh-pages && git checkout -)
  rm -rf "$PROJECT/.gh-pages"
  git -C "$PROJECT" worktree add -f "$PROJECT/.gh-pages" gh-pages
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/.gh-pages/"
  touch "$PROJECT/.gh-pages/.nojekyll"
  (cd "$PROJECT/.gh-pages" && git add -A && git commit -m "Deploy $(date -u +%F_%T)" || true && git push origin gh-pages)
}

deploy_to_docs(){
  require rsync
  mkdir -p "$PROJECT/docs"
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/docs/"
  (cd "$PROJECT" && git add docs && git commit -m "Deploy docs $(date -u +%F_%T)" || true && git push)
}

wait_until_live(){
  local url="$1" tries=60
  for _ in $(seq 1 $tries); do code="$(curl -s -o /dev/null -w '%{http_code}' "$url" || true)"; [[ "$code" == "200" ]] && return 0; sleep 2; done
  return 1
}

usage(){ echo "$(basename "$0") --project PATH [--target auto|gh-pages|docs]"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) shift; PROJECT="$(abs "${1:-}")";;
    --port) shift; PORT="${1:-8080}";;
    --renderer) shift; RENDERER="${1:-html}";;
    --target) shift; TARGET="${1:-auto}";;
    --no-open-local) OPEN_LOCAL=0;;
    --no-open-pages) OPEN_GHPAGES=0;;
    --browsers) shift; BROWSERS="${1:-chrome,safari}";;
    -h|--help) usage; exit 0;;
    *) die "Onbekende optie: $1";;
  esac; shift || true
done

require git; require flutter; require python3; require curl
[[ -d "$PROJECT" ]] || die "Projectpad bestaat niet: $PROJECT"

git_parse_remote
compute_pages_url
ensure_web
build_web

[[ "$TARGET" == auto ]] && TARGET="$(detect_pages_source)"
if [[ "$TARGET" == gh-pages ]]; then
  deploy_to_gh_pages
  activate_pages gh-pages
else
  deploy_to_docs
  activate_pages docs
fi

[[ "$OPEN_GHPAGES" == 1 ]] && open_browsers "$PAGES_URL" || true
wait_until_live "$PAGES_URL" || log "Nog niet live; probeer later opnieuw."
log "Klaar: $PAGES_URL"
