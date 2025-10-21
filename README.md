# csad2526ki405vladyslavvoroniak5

This repository contains a tiny C++ project with a simple `add(int,int)` function and Google Test-based unit tests.

## Requirements
- C++ compiler (AppleClang / clang++ on macOS)
- CMake 3.10+

If you installed the CMake app on macOS (GUI), the `cmake` binary may be located at `/Applications/CMake.app/Contents/bin/cmake`. If you installed CMake via Homebrew, it will typically be on your PATH at `/opt/homebrew/bin/cmake`.

## Build (recommended)
Open a zsh terminal in the project root and run the commands below.

If `cmake` is on PATH (e.g. installed via Homebrew):
```bash
mkdir -p build
cd build
cmake ..
cmake --build .
```

If you have CMake.app installed and `cmake` is not on PATH:
```bash
mkdir -p build
cd build
/Applications/CMake.app/Contents/bin/cmake ..
/Applications/CMake.app/Contents/bin/cmake --build .
```

The above will build two executables:
- `csad2526ki405vladyslavvoroniak5` — the main program (prints a message and uses `add`).
- `unit_tests` — the Google Test executable that runs the unit tests.

## Run tests
You can run tests via `ctest` (if available) or run the test binary directly.

Using `ctest` (preferred if available):
```bash
cd build
ctest --output-on-failure
```

Run the test binary directly:
```bash
cd build
./unit_tests
```

### Build and run only the test executable
If you want to configure and build just the test target (faster than a full build), you can run:
```bash
mkdir -p build
cd build
# configure the project (this downloads and configures googletest via FetchContent)
/Applications/CMake.app/Contents/bin/cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
# build only the unit_tests target
/Applications/CMake.app/Contents/bin/cmake --build . --target unit_tests
```

Now run the test binary:
```bash
./unit_tests
```

### Run a single GoogleTest
You can run only tests that match a filter using the `--gtest_filter` flag. For example:
```bash
./unit_tests --gtest_filter=AdditionTests.Positives
```

### Helper script
You can also use the provided helper script to do a clean rebuild:
```bash
./scripts/rebuild.sh
```

## Notes
- The project uses CMake's `FetchContent` to download GoogleTest at configure time. The first configure may take longer while GoogleTest is downloaded and built.
- If you prefer to have `cmake` and `ctest` available on your PATH, install CMake with Homebrew:
```bash
brew install cmake
```

If you want, I can add a GitHub Actions workflow that builds the project and runs tests on each push/PR.

