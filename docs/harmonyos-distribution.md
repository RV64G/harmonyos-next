# HarmonyOS Distribution Notes

This document explains the difference between the current working HAP and a build suitable for wider testing or AppGallery distribution.

## Current Build

Current working HAP:

```text
build/ohos/hap/entry-default-signed.hap
```

It was produced with local automatic debug signing during development, but it is not a release/public distribution package. The public `ohos/build-profile.json5` intentionally does not include local signing material.

If DevEco Studio writes local `.ohos/config` paths or signing passwords into `ohos/build-profile.json5`, do not publish that version as-is.

## Why Debug Signing Is Not Enough

DevEco automatic signing is meant for local development and registered test devices. It makes the app installable on the developer's own phone/emulator, but it does not mean arbitrary HarmonyOS NEXT users can install the HAP directly.

For wider testing, the project needs one of:

- a proper testing distribution through AppGallery Connect,
- a release/test signing setup accepted by the target devices,
- or developer-oriented sideload instructions for technical testers.

## AppGallery Connect Testing Path

Huawei AppGallery Connect supports HarmonyOS testing distribution. Open testing supports inviting up to 5000 users, while internal testing supports around 100 users and is described as generally avoiding manual review for faster test publishing.

Useful official references:

- AppGallery Connect overview: https://developer.huawei.com/consumer/cn/doc/overview/AppGallery-connect
- Open Testing service: https://developer.huawei.com/consumer/cn/agconnect/open-test/
- AppGallery distribution service: https://developer.huawei.com/consumer/cn/agconnect/distribute

## Before Wider Testing

Minimum checklist:

- [ ] Produce a release/profile HAP or APP package rather than a debug HAP.
- [x] Remove local signing passwords and local `.ohos/config` paths from public files.
- [ ] Decide package name, app label, icon, and brand usage with Lichess.
- [ ] Decide how official builds should receive `LICHESS_WS_SECRET`; the public source does not hard-code the working value.
- [ ] Publish full corresponding GPL-3.0 source code.
- [ ] Add privacy policy wording for HarmonyOS distribution if needed.
- [ ] Confirm OAuth callback behavior after install from the target distribution channel.
- [ ] Confirm Stockfish and SQLite libraries load on arm64 release builds.
- [ ] Run at least one upgrade install test, one clean install test, and one uninstall/reinstall test.
- [ ] Test login, online play, puzzles, analysis, local engine, in-app browser, and settings.
- [ ] Decide push notification strategy before claiming feature parity.

## API / SDK Compatibility

Current project settings:

- `compatibleSdkVersion`: `5.1.0(18)`
- `targetSdkVersion`: `6.1.1(24)`
- `runtimeOS`: `HarmonyOS`

This means the configured compatibility floor is HarmonyOS API 18, while the target SDK is API 24. Actual compatibility still depends on Flutter-ohos, ArkWeb PlatformView behavior, native libraries, and system browser OAuth callback behavior on real devices.
