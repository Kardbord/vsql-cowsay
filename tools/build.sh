#!/usr/bin/env bash

# Copyright (c) 2026 VillageSQL Contributors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <https://www.gnu.org/licenses/>.

set -eo pipefail

FROM_SCRATCH=0
TESTS=0
CMAKE_ARGS=(-DCMAKE_EXPORT_COMPILE_COMMANDS=ON)
[[ -n "${VillageSQL_BUILD_DIR:-}" ]] && CMAKE_ARGS+=(-DVillageSQL_BUILD_DIR="${VillageSQL_BUILD_DIR}")
[[ -n "${VillageSQL_SDK_DIR:-}" ]]   && CMAKE_ARGS+=(-DVillageSQL_SDK_DIR="${VillageSQL_SDK_DIR}")
MAKE_ARGS=(-j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)")

function usage() {
  cat <<EOF
NAME
  ${0##*/}

SYNOPSIS
  ${0##*/} [-h] [-s] [-t] [-m ARG [-m ARG]...] [-c ARG [-c ARG]...]

  This script builds the vsql-cowsay extension.

OPTIONS
  -h Prints this usage message.
  -s Performs the build from scratch.
  -t Builds and runs tests.
  -m ARG Specifies an argument to pass to make (or ninja, if it is available). Can be specified multiple times.
  -c ARG Specifies an argument to pass to cmake. Can be specified multiple times.

ENVIRONMENT
  VillageSQL_BUILD_DIR The path to an existing VillageSQL build to override automatic detection and dev server download
  VillageSQL_SDK_DIR   The path to an existing VillageSQL SDK installation to override automatic detection
EOF
}

function process_args() {
  while getopts "m:c:hst" opt; do
    case "${opt}" in
    m)
      MAKE_ARGS+=("${OPTARG}")
      ;;
    c)
      CMAKE_ARGS+=("${OPTARG}")
      ;;
    s)
      FROM_SCRATCH=1
      ;;
    h)
      usage
      exit 0
      ;;
    t)
      TESTS=1
      ;;
    *)
      usage
      exit 1
      ;;
    esac
  done
  shift $((OPTIND - 1))
}

function get_builder {
  if ! command -v cmake >/dev/null; then
    echo "cmake not found, please install it to continue." >&2
    exit 1
  fi
  if command -v ninja >/dev/null; then
    echo "ninja"
  elif command -v make >/dev/null; then
    echo "make"
  else
    echo "No build tool found. Please install either 'make' or 'ninja'." >&2
    exit 1
  fi
}

function build {
  local builder
  builder=$(get_builder)
  [[ "${builder}" = "ninja" ]] && CMAKE_ARGS+=(-GNinja)

  if [[ "${FROM_SCRATCH}" = 1 ]]; then
    rm -rf ./build
  fi
  cmake -S . -B build "${CMAKE_ARGS[@]}"
  cmake --build build -- "${MAKE_ARGS[@]}"
  cmake --install build
  if [[ "${TESTS}" = 1 ]]; then
    cmake --build build -- run-mtr
  fi
}

function main {
  pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null
  process_args "${@}"
  build
  popd >/dev/null
}

main "${@}"
