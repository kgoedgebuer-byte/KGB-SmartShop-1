#!/bin/bash
set -e

echo "🔧 Fix GitHub Pages root + rebuild Flutter..."

# 1️⃣ Nieuwe build maken
flutter clean >/dev/null 2>&1 || true
flutter pub get >/dev/null 2>&1 || true
flutter build web --release

# 2️⃣ Docs-map opnieuw aanmaken
rm -rf docs
mkdir docs
cp -r build/web/* docs/

# 3️⃣ Flutter index patchen voor GitHub Pages
INDEX_FILE="docs/index.html"
if grep -q 'base href="/"' "$INDEX_FILE"; then
  sed -i.bak 's|<base href="/"|<base href="./"|g' "$INDEX_FILE"
  echo "✅ Base href aangepast naar relatieve pad"
fi

# 4️⃣ Push naar GitHub
git add .
git commit -m "🩹 Fix: relative base path for GitHub Pages" || true
git push origin main --force

echo "🌍 Openen in browser..."
sleep 10
open -a "Safari" "https://kgoedgebuer-byte.github.io/KGB-SmartShop-1/?t=$(date +%s)"
