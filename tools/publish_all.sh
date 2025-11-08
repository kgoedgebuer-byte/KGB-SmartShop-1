#!/bin/bash
set -e

echo "🚀 KGB SmartShop: volledige automatische build + deploy + open"

flutter clean >/dev/null 2>&1 || true
flutter pub get >/dev/null 2>&1 || true
flutter build web --release

rm -rf docs/*
cp -r build/web/* docs/

git add .
git commit -m "🔄 Auto-publish $(date '+%Y-%m-%d %H:%M:%S')" || true
git push origin main

echo "⏳ Wachten op GitHub Pages..."
sleep 10

URL="https://kgoedgebuer-byte.github.io/KGB-SmartShop-1/"
open -a "Safari" "$URL?ts=$(date +%s)" >/dev/null 2>&1 || true
open -a "Google Chrome" "$URL?ts=$(date +%s)" >/dev/null 2>&1 || true

echo "✅ Klaar! App online en geopend."
