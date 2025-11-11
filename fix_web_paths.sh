#!/bin/bash
set -e

echo "🔍 Controleren van Flutter web build structuur..."

if [ ! -d "build/web" ]; then
  echo "⚠️  Geen web build gevonden. Eerst opnieuw bouwen..."
  flutter build web --release
fi

echo "🧹 Oude docs map verwijderen..."
rm -rf docs
mkdir docs

echo "📦 Kopiëren van build/web naar docs..."
cp -R build/web/* docs/

INDEX_FILE="docs/index.html"

if grep -q "/flutter_bootstrap.js" "$INDEX_FILE"; then
  echo "🔧 Fix: pad naar flutter_bootstrap.js aanpassen..."
  sed -i '' 's|/flutter_bootstrap.js|flutter_bootstrap.js|g' "$INDEX_FILE"
fi

if grep -q "/main.dart.js" "$INDEX_FILE"; then
  echo "🔧 Fix: pad naar main.dart.js aanpassen..."
  sed -i '' 's|/main.dart.js|main.dart.js|g' "$INDEX_FILE"
fi

if grep -q "/manifest.json" "$INDEX_FILE"; then
  echo "🔧 Fix: pad naar manifest.json aanpassen..."
  sed -i '' 's|/manifest.json|manifest.json|g' "$INDEX_FILE"
fi

echo "✅ Alle paden gefixt!"
echo "🧠 Controleer lokaal met:  open docs/index.html"
