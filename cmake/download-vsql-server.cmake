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

# Called from CMakeLists.txt at build time by the villagesql-dev-server target.
# Pass -D variables: VERSION, PRODUCT, OS, ARCH, DEST_DIR

set(tarball_name "villagesql-dev-server-${PRODUCT}_${VERSION}-${OS}-${ARCH}.tar.gz")
set(tarball_path "${DEST_DIR}/${tarball_name}")
set(url "https://github.com/villagesql/villagesql-server/releases/download/release/${VERSION}/${tarball_name}")

get_filename_component(_dev_server_dir "${DEST_DIR}/villagesql-dev-server-${PRODUCT}_${VERSION}-${OS}-${ARCH}" ABSOLUTE)

if(EXISTS "${_dev_server_dir}/villagesql")
  message(STATUS "VillageSQL dev server already downloaded at ${_dev_server_dir}")
  return()
endif()

message(STATUS "Downloading VillageSQL dev server ${VERSION} (${OS}-${ARCH})...")
file(DOWNLOAD "${url}" "${tarball_path}"
  STATUS _dl_status
  SHOW_PROGRESS)
list(GET _dl_status 0 _dl_code)
if(NOT _dl_code EQUAL 0)
  list(GET _dl_status 1 _dl_msg)
  message(FATAL_ERROR
    "Failed to download VillageSQL dev server.\n"
    "  URL: ${url}\n"
    "  Error: ${_dl_msg}\n"
    "Check that the version (${VERSION}) and product (${PRODUCT}) are correct.")
endif()

message(STATUS "Extracting ${tarball_name}...")
execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar xzf "${tarball_path}"
  WORKING_DIRECTORY "${DEST_DIR}"
  RESULT_VARIABLE _tar_result)
if(NOT _tar_result EQUAL 0)
  message(FATAL_ERROR "Failed to extract dev server tarball: ${tarball_path}")
endif()

file(REMOVE "${tarball_path}")
message(STATUS "VillageSQL dev server ready at ${_dev_server_dir}")
