#!/bin/bash
set -e

# Controle: juiste main.dart?
if ! grep -q "SmartShopHome" lib/main.dart; then
  echo "❌ lib/main.dart is NIET de juiste versie (met SmartShopHome). 
Eerst plakken!"
  exit 1
fi

echo "✅ main.dart correct gevonden."

# Schoonmaken + dependencies
flutter clean
flutter pub get

# Webbuild met juiste pad
flutter build web --release --base-href "/KGB-SmartShop-1/"

# Oude docs vervangen door nieuwe build
rm -rf docs
mkdir docs
cp -R build/web/* docs/

# 404 -> index.html zodat Safari niet wit blijft
cat > docs/404.html <<EOF
<!doctype html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=index.html">
  </head>
  <body></body>
</html>
EOF

# Commit & push
git add .
git commit -m "Auto-deploy nieuwste SmartShop build" || echo "⚠️ Niks te 
committen"
git push origin main --force

# Open beide browsers (met verse cache)
open -a "Google Chrome" 
"https://kgoedgebuer-byte.github.io/KGB-SmartShop-1/?v=$(date +%s)"
open -a "Safari" 
"https://kgoedgebuer-byte.github.io/KGB-SmartShop-1/?v=$(date +%s)"

