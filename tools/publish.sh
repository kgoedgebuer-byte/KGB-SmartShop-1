#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."   # naar projectroot
if [ ! -x tools/deploy_versioned.sh ]; then
  echo "✖ tools/deploy_versioned.sh ontbreekt of is niet uitvoerbaar"; exit 1
fi
PWA=0 bash tools/deploy_versioned.sh
