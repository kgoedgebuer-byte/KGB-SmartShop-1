#!/usr/bin/env bash
set -Eeuo pipefail

# ---- Config (env override) ----
PROJECT_DEFAULT="$HOME/Desktop/Oud_SmartShop/smartshoplist_v140"
PROJECT="${PROJECT:-$PROJECT_DEFAULT}"
RENDERER="${RENDERER:-html}"
BROWSERS="${BROWSERS:-chrome,safari}"
OPEN_GHPAGES="${OPEN_GHPAGES:-1}"
TARGET="${TARGET:-auto}" # auto|gh-pages|docs

# ---- Utils ----
log(){ printf "▶ %s\n" "$*"; }
die(){ printf "✖ %s\n" "$*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null 2>&1 || die "Tool ontbreekt: $1"; }

# Parse OWNER/REPO uit git remote (HTTPS of SSH), zonder fragile regex
parse_owner_repo() {
  local url; url="$(git -C "$PROJECT" remote get-url origin)"
  local pair
  pair="$(python3 -c 'import sys, urllib.parse
u=sys.argv[1].strip()
if u.startswith("git@"):
  s=u.split(":",1)[1]
else:
  p=urllib.parse.urlparse(u); s=p.path.lstrip("/")
owner,repo=s.split("/",1)
if repo.endswith(".git"): repo=repo[:-4]
print(owner+" "+repo)' "$url")" || true
  OWNER="${pair%% *}"; REPO="${pair#* }"
  [[ -n "$OWNER" && -n "$REPO" ]] || die "Onbekende git remote: $url"
}

is_user_site_repo(){ [[ "$REPO" == "${OWNER}.github.io" ]]; }
pages_url(){ is_user_site_repo && echo "https://${OWNER}.github.io/" || echo "https://${OWNER}.github.io/${REPO}/"; }

supports_flag(){ flutter build web -h 2>&1 | grep -q -- "$1"; }

# ---- Build (met juiste base-href) + SW uit + cache-bust ----
ensure_web_target(){
  log "Flutter web inschakelen…"; flutter config --enable-web >/dev/null || true
  [[ -f "$PROJECT/web/index.html" ]] || (cd "$PROJECT" && flutter create .)
}

build_web(){
  local base="/"; is_user_site_repo || base="/${REPO}/"
  local cmd=(flutter build web --release --base-href "$base")
  supports_flag "--web-renderer" && cmd+=("--web-renderer" "$RENDERER")
  log "Build: ${cmd[*]}"
  (cd "$PROJECT" && flutter pub get && "${cmd[@]}")
  [[ -f "$PROJECT/build/web/index.html" ]] || die "build/web/index.html ontbreekt"
}

disable_sw_and_bust_cache(){
  local d="$PROJECT/build/web"
  python3 - "$d" <<'PY'
import os,re,time,sys
d=sys.argv[1]; p=os.path.join(d,"index.html")
s=open(p,"r",encoding="utf-8").read()
# zet serviceWorkerVersion uit, maar laat boot-script intact
s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
# cache-bust
ts=str(int(time.time()))
s=s.replace('src="flutter.js"', f'src="flutter.js?v={ts}"')
s=s.replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={ts}"')
# unregister + caches leegmaken
extra=("<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations()"
       ".then(function(rs){rs.forEach(function(r){try{r.unregister()}catch(e){}})})}"
       "if(window.caches&&caches.keys){caches.keys().then(function(keys){keys.forEach(function(k){caches.delete(k)})})}"
       "}catch(e){}})();</script>")
s=re.sub(r"</body>", extra+"</body>", s, flags=re.I)
open(p,"w",encoding="utf-8").write(s)
for fn in ("flutter_service_worker.js","firebase-messaging-sw.js"):
    fp=os.path.join(d,fn)
    if os.path.exists(fp):
        try: os.remove(fp)
        except: pass
PY
}

# ---- Deploy (gh-pages of docs) ----
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

detect_pages_source(){
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    local j b p
    if j="$(gh api "repos/${OWNER}/${REPO}/pages" 2>/dev/null)"; then
      b="$(python3 - <<'PY' "$j"
import sys,json; print(json.loads(sys.argv[1]).get("source",{}).get("branch",""))
PY
)"; p="$(python3 - <<'PY' "$j"
import sys,json; print(json.loads(sys.argv[1]).get("source",{}).get("path",""))
PY
)"
      [[ "$b" == "gh-pages" && "$p" == "/" ]] && { echo gh-pages; return; }
      [[ "$b" == "main" && "$p" == "/docs" ]] && { echo docs; return; }
    fi
  fi
  git -C "$PROJECT" ls-remote --heads origin gh-pages >/dev/null 2>&1 && { echo gh-pages; return; }
  echo docs
}

deploy_gh_pages(){
  need rsync
  (cd "$PROJECT" && git fetch origin --prune || true)
  git -C "$PROJECT" show-ref --verify --quiet refs/heads/gh-pages || (cd "$PROJECT" && git checkout --orphan gh-pages && git reset --hard && echo "#" > README.md && git add README.md && git commit -m "init gh-pages" && git push -u origin gh-pages && git checkout -)
  rm -rf "$PROJECT/.gh-pages"; git -C "$PROJECT" worktree add -f "$PROJECT/.gh-pages" gh-pages
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/.gh-pages/"; touch "$PROJECT/.gh-pages/.nojekyll"
  (cd "$PROJECT/.gh-pages" && git add -A && git commit -m "Deploy $(date -u +%F_%T)" || true && git push origin gh-pages)
}

deploy_docs(){
  need rsync
  mkdir -p "$PROJECT/docs"
  rsync -a --delete "$PROJECT/build/web/" "$PROJECT/docs/"
  (cd "$PROJECT" && git add docs && git commit -m "Deploy docs $(date -u +%F_%T)" || true && git push)
}

open_browsers(){
  local base="$1" ts="$(date +%s)" url
  [[ "$base" == *\?* ]] && url="${base}&ts=${ts}" || url="${base}?ts=${ts}"
  [[ "$BROWSERS" == *safari* ]] && open -a "Safari" "$url" 2>/dev/null || true
  [[ "$BROWSERS" == *chrome* ]] && open -a "Google Chrome" "$url" 2>/dev/null || true
}

wait_until_live(){
  local url="$1" tries=60
  for _ in $(seq 1 $tries); do
    code="$(curl -s -o /dev/null -w '%{http_code}' "$url" || true)"
    [[ "$code" == "200" ]] && return 0
    sleep 2
  done
  return 1
}

# ---- Main ----
need git; need flutter; need python3; need curl
[[ -d "$PROJECT" ]] || die "Projectpad bestaat niet: $PROJECT"

parse_owner_repo
APP_URL="$(pages_url)"
ensure_web_target
build_web
disable_sw_and_bust_cache

[[ "$TARGET" == "auto" ]] && TARGET="$(detect_pages_source)"
if [[ "$TARGET" == "gh-pages" ]]; then
  deploy_gh_pages; activate_pages gh-pages
else
  deploy_docs; activate_pages docs
fi

[[ "$OPEN_GHPAGES" == "1" ]] && open_browsers "$APP_URL" || true
wait_until_live "$APP_URL" || log "Nog niet live (probeer zo nog eens)."
log "Klaar: $APP_URL"
