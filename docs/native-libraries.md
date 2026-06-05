# Native Libraries

This document records how the current HarmonyOS NEXT prototype obtains the native libraries required by SQLite and local Stockfish.

## Bundled Libraries

```text
ohos/entry/libs/arm64-v8a/libsqlite3.so
ohos/entry/libs/arm64-v8a/libmultistockfish_variant.so
ohos/entry/libs/arm64-v8a/libc++_shared.so
ohos/entry/libs/x86_64/libsqlite3.so
ohos/entry/libs/x86_64/libmultistockfish_variant.so
ohos/entry/libs/x86_64/libc++_shared.so
```

## Stockfish Variant Build

The current `libmultistockfish_variant.so` is built from the `multistockfish_variant` package sources, using the Fairy-Stockfish sources bundled by that package.

Example arm64 build command used locally:

```powershell
& 'D:\DevEcoStudio\sdk\default\openharmony\native\build-tools\cmake\bin\cmake.exe' `
  -S 'C:\Users\lenovo\AppData\Local\Pub\Cache\hosted\pub.dev\multistockfish_variant-0.1.1\android' `
  -B 'build\ohos_stockfish_variant_arm64' `
  -G Ninja `
  -DCMAKE_MAKE_PROGRAM='D:\DevEcoStudio\sdk\default\openharmony\native\build-tools\cmake\bin\ninja.exe' `
  -DCMAKE_TOOLCHAIN_FILE='D:\DevEcoStudio\sdk\default\openharmony\native\build\cmake\ohos.toolchain.cmake' `
  -DOHOS_ARCH=arm64-v8a `
  -DOHOS_PLATFORM_LEVEL=24 `
  -DCMAKE_BUILD_TYPE=Debug `
  -DCMAKE_CXX_FLAGS='-std=c++17 -DNNUE_EMBEDDING_OFF -DUSE_PTHREADS -DIS_64BIT -DUSE_POPCNT -DUSE_NEON'

& 'D:\DevEcoStudio\sdk\default\openharmony\native\build-tools\cmake\bin\cmake.exe' `
  --build 'build\ohos_stockfish_variant_arm64' `
  --config Debug `
  --parallel 8
```

Output:

```text
build/ohos_stockfish_variant_arm64/libmultistockfish_variant.so
```

The matching `libc++_shared.so` was copied from:

```text
D:\DevEcoStudio\sdk\default\openharmony\native\llvm\lib\aarch64-linux-ohos\libc++_shared.so
```

## Follow-Up

- Add a checked-in script to rebuild x86_64 and arm64 Stockfish libraries reproducibly.
- Document SQLite source/build provenance.
- Confirm release-mode native library behavior, not only debug builds.
- Preserve upstream license files for Stockfish/Fairy-Stockfish/multistockfish.
