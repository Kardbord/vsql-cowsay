# vsql_cowsay

A cowsay extension for [VillageSQL](https://villagesql.com/docs) — the classic
ASCII cow with a speech bubble, right in your SQL queries.

```sql
SELECT cowsay('Hello, world!');
```

```txt
Hello, world!
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

## Quick Start

```bash
./tools/build.sh
```

This creates `vsql_cowsay.veb` in the build directory. Load it in VillageSQL:

```sql
INSTALL EXTENSION vsql_cowsay;
SELECT cowsay('Hello, world!');
```

## Prerequisites

- CMake 3.18+
- C++ compiler with C++17 support

You don't need VillageSQL pre-installed. The build script downloads a prebuilt
SDK automatically if it isn't found locally.

If you have an existing VillageSQL build tree, point at it to skip the download:

```bash
cmake .. -DVillageSQL_BUILD_DIR="$HOME/build/villagesql"
```

## Project Structure

```
vsql_cowsay/
├── manifest.json           # Extension metadata
├── CMakeLists.txt          # Build configuration
├── cmake/                  # CMake modules
├── src/                    # C++ implementation
└── mysql-test/             # Test suite (MTR)
    ├── t/                  # .test files
    └── r/                  # .result files
```

## Testing

```bash
./tools/build.sh -t
```

On first run this downloads a prebuilt VillageSQL dev server (~140 MB). The
server is cached for subsequent runs.

## Troubleshooting

**SDK download fails:** Set the version explicitly:

```bash
cmake .. -DVillageSQL_FETCH_SDK_VERSION=0.0.6
```

**Extension not found:** Verify `INSTALL EXTENSION vsql_cowsay` uses the correct
name. Check installed extensions:

```sql
SELECT * FROM INFORMATION_SCHEMA.EXTENSIONS;
```

## Resources

- [VillageSQL Documentation](https://villagesql.com/docs)
- [Writing C++ Extensions](https://villagesql.com/docs/guides/cpp-extensions)

## License

GPL-2.0. See [LICENSE](./LICENSE) for details.
