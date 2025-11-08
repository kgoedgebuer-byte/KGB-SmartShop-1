#!/usr/bin/env bash
set -Eeuo pipefail
require(){ command -v "$1" >/dev/null 2>&1 || { echo "✖ Tool ontbreekt: $1"; exit 1; }; }
require git; require curl

remote_url="$(git remote get-url origin)"
if [[ "$remote_url" =~ github.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
else
  echo "✖ Kan git remote niet parsen: $remote_url"; exit 1
fi

# Bepaal verwachte Pages-URL
if [[ "$repo" == "${owner}.github.io" ]]; then
  pages_url="https://${owner}.github.io/"
else
  pages_url="https://${owner}.github.io/${repo}/"
fi

echo "▶ Verwachte Pages-URL: $pages_url"

# Check of gh-pages branch bestaat en index.html bevat
echo "▶ Controleren of 'gh-pages' op remote bestaat…"
if git ls-remote --heads origin gh-pages >/dev/null 2>&1; then
  git fetch origin gh-pages:refs/remotes/origin/gh-pages >/dev/null 2>&1 || true
  first10="$(git ls-tree -r --name-only origin/gh-pages | sed -n '1,10p' || true)"
  echo "— Bestanden op gh-pages (eerste 10):"
  echo "$first10"
  if ! echo "$first10" | grep -q '^index.html$'; then
    echo "✖ 'index.html' niet gevonden op gh-pages → eerst (opnieuw) deployen."
  fi
else
  echo "✖ Remote branch 'gh-pages' ontbreekt → eerst deployen."
fi

# Probeer Pages automatisch te activeren via GitHub CLI
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "▶ Configureren GitHub Pages bron → gh-pages /"
    # Maak aan (POST) of update (PUT), maakt niet uit; PUT dekt beide gevallen
    gh api -X PUT "repos/${owner}/${repo}/pages" -f "source[branch]=gh-pages" -f "source[path]=/" >/dev/null 2>&1 || {
      echo "⚠ Kon Pages niet configureren via API (mogelijk ontbrekende rechten)."
    }
  else
    echo "⚠ 'gh' niet ingelogd (gh auth login -w) — sla Pages-activatie over."
  fi
else
  echo "ℹ Geen 'gh' CLI — sla Pages-activatie over. (Optioneel: brew install gh)"
fi

# Test HTTP status van de verwachte URL
code="$(curl -s -o /dev/null -w '%{http_code}' "$pages_url" || true)"
echo "▶ HTTP-status op $pages_url = $code"
if [[ "$code" != "200" ]]; then
  echo "ℹ Als je net gedeployd hebt en Pages zojuist is geactiveerd: voer het deploy-script nogmaals uit."
fi

# Open in Safari/Chrome indien aanwezig
if command -v open >/dev/null 2>&1; then
  open -a "Safari" "$pages_url" 2>/dev/null || true
  open -a "Google Chrome" "$pages_url" 2>/dev/null || true
fi
