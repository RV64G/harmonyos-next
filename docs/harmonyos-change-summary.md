# HarmonyOS NEXT Change Summary

Base: `lichess-org/mobile` `v0.24.1` (`895f1ce`, 2026-05-26).

This document summarizes the current HarmonyOS NEXT port for review before opening the GitHub issue.

## Platform Project

Added a HarmonyOS project under `ohos/`:

- `AppScope/app.json5`: bundle metadata, app label, app icon.
- `build-profile.json5`: local signing and SDK configuration. Do not publish the current local signing material as-is.
- `entry/src/main/module.json5`: `EntryAbility`, deep link scheme, startup window, permissions.
- `entry/src/main/ets/entryability/EntryAbility.ets`: Flutter engine setup, plugin registration, deep link forwarding.
- `entry/src/main/ets/plugins/UrlLauncherPlugin.ets`: URL launcher shim, in-app browser routing, OAuth external browser routing.
- `entry/src/main/ets/platform/LichessBrowserPlatformView.ets`: ArkWeb PlatformView for ordinary web links.
- `entry/src/main/resources/...`: app icon, splash icon, labels, startup colors, pages.

## Dart Integration

Main HarmonyOS-specific Dart additions:

- `lib/src/utils/ohos_stubs.dart`: HarmonyOS plugin and platform shims.
- `lib/src/widgets/ohos_in_app_browser.dart`: Flutter route wrapping the ArkWeb PlatformView.
- `lib/src/network/http_client_stub.dart`: platform compatibility stub.

Main adapted existing files:

- `lib/main.dart`: HarmonyOS startup handling and Firebase guard.
- `lib/src/app.dart`: in-app browser registration and debug banner disabled.
- `lib/src/app_links_service.dart`: HarmonyOS deep link handling and in-app web routing.
- `lib/src/binding.dart`: Firebase/Crashlytics/Messaging guards and platform-safe bindings.
- `lib/src/constants.dart`: production host configuration for tested builds.
- `lib/src/model/auth/auth_repository.dart`: OAuth launch/callback handling adjusted for HarmonyOS.
- `lib/src/network/connectivity.dart`: HarmonyOS-safe connectivity behavior.
- `lib/src/model/puzzle/puzzle_providers.dart`: timeout/fallback behavior for puzzle waterfall.
- `lib/src/model/game/game_history.dart`: network-first fallback where local storage is unreliable.
- `lib/src/view/settings/settings_screen.dart`: HarmonyOS app rating placeholder and language setting behavior.
- `lib/src/widgets/adaptive_choice_picker.dart`: settings picker interaction fix.
- `lib/src/theme.dart`, `lib/src/view/account/account_menu.dart`: platform detection fixes.
- `lib/src/widgets/expanded_section.dart`: animation/layout compatibility fix.

## Native Libraries

Bundled native libraries:

- `ohos/entry/libs/x86_64/libmultistockfish_variant.so`
- `ohos/entry/libs/x86_64/libc++_shared.so`
- `ohos/entry/libs/x86_64/libsqlite3.so`
- `ohos/entry/libs/arm64-v8a/libmultistockfish_variant.so`
- `ohos/entry/libs/arm64-v8a/libc++_shared.so`
- `ohos/entry/libs/arm64-v8a/libsqlite3.so`

Stockfish was built from the existing `multistockfish_variant` sources using the HarmonyOS NDK toolchain.

## Package Changes

- `pubspec.yaml` / `pubspec.lock`: local override for `third_party/multistockfish`, Flutter-ohos compatible dependency resolution.
- `third_party/multistockfish`: local package copy with HarmonyOS dynamic library loading support.

## User-Visible HarmonyOS Adjustments

- App name: `Lichess`.
- App icon: official black background / white horsey icon from existing upstream assets.
- Startup window: black background with large white horsey splash icon.
- Ordinary web links: in-app ArkWeb browser.
- OAuth login: system browser, because Cloudflare verification was unreliable inside ArkWeb.
- `Rate this app`: HarmonyOS placeholder message until AppGallery listing exists.

## Known Follow-Up Work

- Replace local debug signing with publishable signing configuration.
- Prepare release build workflow.
- Decide branding/distribution with Lichess maintainers.
- Implement Push Kit or another notification strategy.
- Add a repeatable native library build script for Stockfish/SQLite.
- Run broader device coverage beyond one real phone and one emulator.
