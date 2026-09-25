#!/usr/bin/env bash
set -euo pipefail

mkdir -p build

if [ -n "${VillageSQL_BUILD_DIR:-}" ]; then
  cmake -S . -B build -DVillageSQL_BUILD_DIR="$VillageSQL_BUILD_DIR"
else
  cmake -S . -B build
fi

cmake --build build -- -j "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
cmake --install build
