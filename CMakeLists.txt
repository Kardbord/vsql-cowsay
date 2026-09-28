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

cmake_minimum_required(VERSION 3.18)
project(vsql_cowsay)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Default to an optimized build. An empty CMAKE_BUILD_TYPE yields -O0 (no
# -O flag applied), which builds and runs but leaves the code unoptimized.
# Override with -DCMAKE_BUILD_TYPE=.
#
# -DWITH_DEBUG=ON means "give me a debug build" -- it takes priority over
# any explicitly passed CMAKE_BUILD_TYPE and forces Debug, so NDEBUG is
# never defined (RelWithDebInfo/Release both define it, which would
# silently compile out every #ifndef NDEBUG check and every assert()).
if(NOT CMAKE_CONFIGURATION_TYPES)
  if(WITH_DEBUG)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
  elseif(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
  endif()
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Extension name
set(EXTENSION_NAME "vsql_cowsay")

# Find VillageSQL SDK
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
find_package(VillageSQL REQUIRED)

message(STATUS "VillageSQL SDK found at: ${VillageSQL_PREFIX}")
message(STATUS "VillageSQL include dir: ${VillageSQL_INCLUDE_DIR}")

# Create the cowsay shared library
add_library(cowsay SHARED
    src/cowsay.cc
)

# Include directories
target_include_directories(cowsay PRIVATE
    ${VillageSQLExtensionFramework_INCLUDE_DIR}
)

# Create the VEB package
vef_create_veb(
    NAME ${EXTENSION_NAME}
    LIBRARY_TARGET cowsay
    MANIFEST ${CMAKE_CURRENT_SOURCE_DIR}/manifest.json
)

# ---------------------------------------------------------------------------
# Test targets
# ---------------------------------------------------------------------------

# Platform detection for dev server tarball
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  set(_vsql_os "linux")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  set(_vsql_os "macos")
else()
  message(FATAL_ERROR "Unsupported platform: ${CMAKE_HOST_SYSTEM_NAME}")
endif()

set(VillageSQL_FETCH_PRODUCT "mysql-8.4" CACHE STRING
  "VillageSQL server product variant to fetch when no local server is available")

set(_vsql_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")

if(VillageSQL_BUILD_DIR)
  set(_vsql_test_base "${VillageSQL_BUILD_DIR}")
  add_custom_target(villagesql-dev-server
    COMMENT "Using VillageSQL server from build tree: ${VillageSQL_BUILD_DIR}"
    COMMAND ${CMAKE_COMMAND} -E echo "VillageSQL server found at ${VillageSQL_BUILD_DIR}/mysql-test/mysql-test-run.pl"
  )
else()
  set(_vsql_test_base
    "${CMAKE_CURRENT_BINARY_DIR}/_deps/villagesql-dev-server-${VillageSQL_FETCH_PRODUCT}_${VillageSQL_FETCH_SDK_VERSION}-${_vsql_os}-${_vsql_arch}")
  add_custom_target(villagesql-dev-server
    COMMENT "Downloading VillageSQL dev server ${VillageSQL_FETCH_SDK_VERSION}..."
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/_deps"
    COMMAND ${CMAKE_COMMAND}
      -D VERSION="${VillageSQL_FETCH_SDK_VERSION}"
      -D PRODUCT="${VillageSQL_FETCH_PRODUCT}"
      -D OS="${_vsql_os}"
      -D ARCH="${_vsql_arch}"
      -D DEST_DIR="${CMAKE_CURRENT_BINARY_DIR}/_deps"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/download-vsql-server.cmake"
    USES_TERMINAL
  )
endif()

set(_vsql_test_runner "${_vsql_test_base}/mysql-test/mysql-test-run.pl")

add_custom_target(run-mtr
  COMMENT "Running MTR test suite for ${EXTENSION_NAME}..."
  COMMAND "${_vsql_test_runner}"
    --veb-source-dir="${CMAKE_CURRENT_BINARY_DIR}"
    --suite="${CMAKE_CURRENT_SOURCE_DIR}/mysql-test"
    --parallel=auto
    --nounit-tests
    --force
    --retry=0
  WORKING_DIRECTORY "${_vsql_test_base}/mysql-test"
  DEPENDS ${EXTENSION_NAME}.veb villagesql-dev-server
)

add_custom_target(run-mtr-record
  COMMENT "Recording MTR test results for ${EXTENSION_NAME}..."
  COMMAND "${_vsql_test_runner}"
    --veb-source-dir="${CMAKE_CURRENT_BINARY_DIR}"
    --suite="${CMAKE_CURRENT_SOURCE_DIR}/mysql-test"
    --record
    --parallel=auto
    --nounit-tests
    --force
    --retry=0
  WORKING_DIRECTORY "${_vsql_test_base}/mysql-test"
  DEPENDS ${EXTENSION_NAME}.veb villagesql-dev-server
)

