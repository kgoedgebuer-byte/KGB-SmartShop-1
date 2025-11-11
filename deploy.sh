#!/bin/bash
echo "🚀 Automatische SmartShop Deploy gestart..."

# Zorg dat we altijd in de juiste map staan
cd ~/Desktop/Oud_SmartShop/smartshoplist_v150 || exit
echo "📂 Map gecontroleerd: $(pwd)"

# Opschonen en opnieuw builden
flutter clean
flutter pub get
flutter build web --release

# Zet build-bestanden klaar voor GitHub Pages
rm -rf docs
mkdir docs
cp -R build/web/* docs/

# Commit en push naar GitHub
git add .
git commit -m "🔄 Automatische SmartShop web build $(date)"
git push origin main

echo "✅ Deploy voltooid! Controleer op:"
echo "👉 https://kgoedgebuer-byte.github.io/KGB-SmartShop-1/"

