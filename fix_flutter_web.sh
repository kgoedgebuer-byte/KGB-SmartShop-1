#!/bin/bash
set -e

echo "🛠️  === KGB SmartShop Flutter Auto Repair & Deploy v2 ==="

# Herstel Flutter indien nodig
if ! command -v flutter &> /dev/null; then
  echo "⚠️  Flutter niet gevonden — opnieuw installeren..."
  mkdir -p ~/development
  cd ~/development
  git clone https://github.com/flutter/flutter.git -b stable
  echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
  source ~/.zshrc
  flutter doctor
  cd ~/Desktop/Oud_SmartShop/smartshoplist_v140
fi

echo "🧹 Cleaning & getting packages..."
flutter clean
flutter pub get

echo "🚀 Building web release..."
flutter build web --release --base-href "/KGB-SmartShop-1/"

# Controleer of build geslaagd is
if [ ! -d "build/web" ]; then
  echo "❌ Build mislukt — herstellen pub-cache..."
  rm -rf ~/.pub-cache
  flutter pub cache repair
  flutter pub get
  flutter build web --release --base-href "/KGB-SmartShop-1/"
fi

# Fix pad in index.html
echo "🔧 Corrigeren van index.html..."
sed -i '' 's|<base href="/">|<base href="/KGB-SmartShop-1/">|' build/web/index.html

# Voeg 404.html toe (voor SPA-navigatie)
cp build/web/index.html build/web/404.html

# GitHub Pages deploy
echo "🌍 Publiceren naar GitHub Pages..."
git checkout gh-pages || git checkout -b gh-pages
rm -rf *
cp -r build/web/* .
git add .
git commit -m "🚀 Auto rebuild and deploy (fixed base-href + 404)"
git push origin gh-pages --force

echo "✅ Klaar! App draait nu correct op GitHub Pages."
