# Public Repository Checklist

Use this before pushing the HarmonyOS NEXT port to `RV64G/harmonyos-next`.

## Must Not Publish

- [ ] Local signing passwords from `ohos/build-profile.json5`.
- [ ] Local `.p12`, `.cer`, or `.p7b` signing files.
- [ ] Absolute local signing paths under `C:\Users\lenovo\.ohos\config`.
- [ ] Temporary screenshots named `tmp_*`.
- [ ] Flutter logs named `flutter_*.log`.
- [ ] Emulator crash logs such as `sysfreeze-*.log`.
- [ ] Build directories: `build/`, `.dart_tool/`, `.hvigor/`, `ohos/.hvigor/`, `ohos/entry/build/`.
- [ ] Generated Flutter assets under `ohos/entry/src/main/resources/rawfile/flutter_assets/`.

## Files That Need Review Before Publishing

- `ohos/build-profile.json5`: currently sanitized; if DevEco rewrites local signing material, sanitize it again before pushing.
- `lib/src/constants.dart`: public source must not hard-code the working `LICHESS_WS_SECRET`; pass it through `--dart-define` for private test builds.
- `third_party/multistockfish`: confirm license files are preserved.
- `ohos/entry/libs/**`: confirm native library licenses and source/build instructions are documented.
- `docs/current-status.md`: update old limitations before making it public.

## Suggested Public Branch

```text
harmonyos-next
```

## Suggested First Push Shape

- Source code and HarmonyOS project files.
- Documentation under `docs/`.
- Native libraries required to run, if license-compatible and documented.
- No local signing secrets.
- No generated logs/screenshots.

## Quick Audit Commands

```powershell
git status --short
rg -n "keyPassword|storePassword|default_ohos_|\\.p12|\\.p7b|\\.cer|debugKey" .
rg --files | rg "^(build/|\\.hvigor/|flutter_.*\\.log|tmp_|sysfreeze-)"
```
