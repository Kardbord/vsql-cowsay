# vsql_cowsay

A cowsay extension for VillageSQL, bringing the classic `cowsay` utility to your
SQL queries.

[VillageSQL documentation](https://villagesql.com/docs) ·
[Writing extensions in C++](https://villagesql.com/docs/guides/cpp-extensions) ·
[Install VillageSQL Server](https://villagesql.com/install)

## What This Is

This extension implements a `cowsay()` SQL function that renders an ASCII cow
with a speech bubble — the same format as the classic Unix `cowsay` utility.
It's built on the VillageSQL extension framework (VEF) using C++.

## Project Structure

```
vsql_cowsay/
├── manifest.json           # Extension metadata (name, version, description, etc.)
├── CMakeLists.txt          # CMake build configuration
├── cmake/
│   ├── FindVillageSQL.cmake           # CMake module for finding VillageSQL
│   └── download-vsql-server.cmake     # Script for lazy dev server download
├── src/
│   └── cowsay.cc          # C++ implementation using VEF API
└── mysql-test/
    ├── t/                 # Test files (.test)
    │   └── cowsay_basic.test
    └── r/                 # Expected results (.result)
        └── cowsay_basic.result
```

## Prerequisites

- CMake 3.18 or higher
- C++ compiler with C++17 support

You do **not** need to pre-install VillageSQL. If `FindVillageSQL.cmake`
doesn't find an existing SDK via any of its standard methods (build directory,
SDK directory, `villagesql_config` in PATH, or `~/.villagesql`), it
automatically downloads a prebuilt SDK from GitHub Releases.

## Building the Extension

Build the extension with CMake:

```bash
mkdir build && cd build
cmake ..
make -j $(getconf _NPROCESSORS_ONLN)
```

If you already have a VillageSQL build directory, you can point at it to skip
the automatic download:

```bash
cmake .. -DVillageSQL_BUILD_DIR="$HOME/build/villagesql"
```

This creates the `vsql_cowsay.veb` package in the build directory.

To install the VEB to the server's `veb_dir` (if you have a server running):

```bash
make install
```

## Using the Extension

After building the VEB file, load the extension in VillageSQL:

```sql
INSTALL EXTENSION vsql_cowsay;
```

Then call the function:

```sql
SELECT cowsay('Hello, world!');
```

## Testing

The extension includes test files using the MySQL Test Runner (MTR) framework.

### Running Tests with make

The easiest way to run tests uses the lazy dev server download. On first run,
it downloads a prebuilt VillageSQL dev server (~140MB) for your platform:

```bash
make run-mtr
```

This automatically:
1. Downloads and extracts the dev server (cached for subsequent runs)
2. Copies the built `.veb` into the server's `lib/veb/`
3. Installs the test suite and runs MTR

### Running Tests Manually

If you already have a VillageSQL server build directory, run MTR directly:

```bash
cd $HOME/build/villagesql/mysql-test
perl mysql-test-run.pl --suite=/path/to/vsql-cowsay/mysql-test

# Run with specific options
perl mysql-test-run.pl --suite=/path/to/vsql-cowsay/mysql-test --parallel=auto
```

To test a VEB you have **not** installed, point MTR at the build directory:

```bash
cd $HOME/build/villagesql/mysql-test
perl mysql-test-run.pl \
  --veb-source-dir=/path/to/vsql-cowsay/build \
  --suite=/path/to/vsql-cowsay/mysql-test
```

### Creating/Updating Test Results

```bash
cd $HOME/build/villagesql/mysql-test
perl mysql-test-run.pl --suite=/path/to/test --record
```

## Customizing This Extension

To add new functions or modify behavior:

1. **Update `manifest.json`**:
   - Change `version` as needed
   - Update `description`, `author`, and other metadata

2. **Update `CMakeLists.txt`**:
   - Change `EXTENSION_NAME` if renaming the extension
   - Add source files to `add_library()` if needed
   - Add dependencies via `target_link_libraries()`

3. **Implement Your Functions**:
   - Modify `src/cowsay.cc` or create new source files
   - Include `<villagesql/vsql.h>` and `using namespace vsql;`
   - Use typed wrapper parameters: `IntArg`, `RealArg`, `StringArg`, `StringResult`, etc.
   - Register functions using `VEF_GENERATE_ENTRY_POINTS()` macro

4. **Create Tests**:
   - Add `.test` files in the `mysql-test/t/` directory
   - Update expected results via `--record` flag
   - Verify your functions work correctly

## Extension Development Tips

- **Extension Naming**: Use underscores in extension names. A hyphenated name
  is a syntax error in `INSTALL EXTENSION` unless backtick-quoted, so
  underscores keep the statement quoting-free
- **Return Types**: Common types are `STRING`, `INT`, `REAL`, or custom types
- **String Results**: Write into `out.buffer()`, then call `out.set_length(n)`
- **NULL Handling**: Call `arg.is_null()` on input args; call
  `out.set_null()` to return NULL
- **Error Handling**: Call `out.error(msg)` to abort with an error;
  `out.warning(msg)` for a warning
- **Testing**: Always test with various inputs including edge cases and NULL
  values

## Example: Adding a New Function

1. Add implementation to `src/cowsay.cc`:

```cpp
void greet_impl(StringArg name, StringResult out) {
    if (name.is_null()) { out.set_null(); return; }
    auto val = name.value();
    auto buf = out.buffer();
    auto len = snprintf(buf.data(), buf.size(), "Hello, %.*s!",
                        (int)val.size(), val.data());
    out.set_length(len);
}
```

2. Register in `VEF_GENERATE_ENTRY_POINTS()`:

```cpp
VEF_GENERATE_ENTRY_POINTS(
  make_extension()
    .func(make_func<&hello_world_impl>("hello_world")
      .returns(STRING)
      .no_params()
      .buffer_size(14)
      .build())
    .func(make_func<&greet_impl>("greet")
      .returns(STRING)
      .param(STRING)
      .buffer_size(256)
      .build())
)
```

3. Rebuild and test:

   ```bash
   cd build
   make -j $(getconf _NPROCESSORS_ONLN)
   ```

## Troubleshooting

### Build Failures

**VillageSQL SDK not found:**
If the automatic download fails, set the version explicitly:
```bash
cmake .. -DVILLAGESQL_SDK_VERSION=0.0.6
```

Or point to an existing installation:
```bash
cmake .. -DVillageSQL_BUILD_DIR="$HOME/build/villagesql"
```

### Extension Loading Issues

**Extension not found after installation:**
- Verify the VEB file was copied to the correct directory
- Check that `INSTALL EXTENSION vsql_cowsay` uses the correct name
- Restart the VillageSQL server if needed

**Function not found:**
- Ensure the extension is installed: `SELECT * FROM INFORMATION_SCHEMA.EXTENSIONS;`
- Try using explicit namespace: `vsql_cowsay.function_name()`
- Check the server's VEF protocol support:
  `SELECT @@villagesql_vef_server_protocol;`

## Resources

- [VillageSQL Documentation](https://villagesql.com/docs)
- [Guide to writing C++ Extensions](https://villagesql.com/docs/guides/cpp-extensions)
- [CMake Documentation](https://cmake.org/documentation/)

## License

This extension is released under the GPL-2.0 license. See the license header
in source files for details.
