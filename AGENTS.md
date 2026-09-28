# AGENTS.md

Guidance for AI coding assistants working with this repository.

**Note**: Also check `AGENTS.local.md` for local overrides when present.

## Project Overview

A VillageSQL extension that renders ASCII cow art with a speech bubble via a
`cowsay()` SQL function. Built on VEF — the VillageSQL Extension Framework.

VEF is a typed C++ API. Functions are written as ordinary C++ functions using
wrapper parameters (`IntArg`, `StringResult`, etc.) and registered with the
`VEF_GENERATE_ENTRY_POINTS()` macro.


**Build system:**
CMake finds the VillageSQL SDK via `find_package()`. If none is found, it
downloads a prebuilt SDK tarball from GitHub Releases. The result is a `.veb`
package (tar archive containing the shared library + manifest). Set
`VillageSQL_BUILD_DIR` to skip the download and use a local build tree.

For complete VEF API coverage — typed wrappers, registration syntax, result
types — see the C++ Development Guide linked in Sources of Truth below.

## Build & Test

```bash
cmake -B build && cmake --build build             # build
cmake --build build --target run-mtr              # test (downloads dev server)
./tools/build.sh [-t] [-s]                        # convenience wrapper
```

## Conventions

- **C++ standard**: C++17
- **Copyright**: Include the GPL-2.0 copyright header in every `.cc`, `.h`,
  `.cpp`, `.hpp`, and `CMakeLists.txt` file (exact header below)
- For anything not listed here, follow the conventions already established in
  existing source files — consistency with surrounding code takes priority

### Required Copyright Header

```
/* Copyright (c) 2026 VillageSQL Contributors
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <https://www.gnu.org/licenses/>.
 */
```

## Sources of Truth

This project defers to the VillageSQL documentation and local source code for
specifics. Do not inline or copy API contracts here — fetch them from the source
when needed.

| Topic | Where to find it |
|---|---|
| VEF API (typed wrappers, registration, result types) | [C++ Development Guide](https://villagesql.com/docs/mysql-8.4/stable/development) |
| Extension naming conventions | [Extension Naming Conventions](https://villagesql.com/docs/mysql-8.4/stable/install) (embedded in install page) |
| CMake variables and build config | `CMakeLists.txt` + `cmake/FindVillageSQL.cmake` |
| Test format (MTR `.test` / `.result` files) | `mysql-test/t/cowsay_basic.test` + `mysql-test/r/cowsay_basic.result` |
| Full documentation index for AI discovery | [`https://villagesql.com/docs/llms.txt`](https://villagesql.com/docs/llms.txt) — start here to find relevant pages |

## Common Tasks

### Add a Function

1. Open `src/cowsay.cc` and write the implementation using typed wrapper
   parameters (args first, result last)
2. Register it in the `VEF_GENERATE_ENTRY_POINTS()` block with
   `make_func<&impl_fn>("sql_name").returns(...).param(...).buffer_size(N).build()`
3. Add a test file in `mysql-test/t/` and expected results in `mysql-test/r/`
4. Build and run tests to verify

### Add a Source File

1. Create the file with the copyright header
2. Add it to `add_library(cowsay SHARED ...)` in `CMakeLists.txt`
3. Create corresponding tests

### Add a Dependency

```cmake
find_package(PackageName REQUIRED)
target_link_libraries(cowsay PRIVATE ${PACKAGE_LIBRARIES})
```

### Test Workflow

Tests use the MySQL Test Runner (MTR). Each `.test` file should install the
extension at the start and uninstall it at the end. Expected output is generated
by running MTR with `--record`:

```bash
# Run tests
cmake --build build --target run-mtr

# Update expected results
cmake --build build --target run-mtr-record
```
