# GitHub Issue / 投稿信

## 提交目标

- 仓库：`lichess-org/mobile`
- 标签建议：`enhancement` / `platform: harmonyos` / `help wanted`
- 标题建议：**HarmonyOS NEXT support: working Flutter-ohos port and request for guidance**


---

## 正文（英文）

---

Hi Lichess team,

First of all, thank you for building and maintaining Lichess and the new Flutter mobile app. As a chess player and Lichess user who recently moved to HarmonyOS NEXT, I noticed that there is currently no official Lichess app for this increasingly popular platform. I have been experimenting with bringing the current `lichess-org/mobile` codebase to HarmonyOS NEXT, and I now have a working prototype running on both the HarmonyOS emulator and a real HarmonyOS NEXT phone.

I would like to share the current state, ask for guidance, and understand whether this is something the Lichess team would be interested in supporting, accepting upstream, or helping shape into an appropriate HarmonyOS platform target.

## Summary

I adapted the official Flutter mobile app to HarmonyOS NEXT using the community-maintained Flutter-ohos engine and a small amount of ArkTS native code. The current prototype is based on `lichess-org/mobile` tag `v0.24.1` (`895f1ce`, May 26, 2026).

The goal was to keep the Dart application as close to upstream as possible. The port currently reuses the existing Lichess app architecture: Riverpod state management, chessground board rendering, dartchess rules, Lichess API integration, WebSocket logic, OAuth PKCE flow, and local Stockfish integration.

## Current status

Tested on:

- Upstream base: `lichess-org/mobile` `v0.24.1` (`895f1ce`)
- HarmonyOS NEXT emulator, x86_64
- Huawei nova 15 Ultra, arm64, HarmonyOS NEXT
- DevEco Studio 6.1.1
- HarmonyOS SDK target API 24

Working in the current prototype:

| Area | Status |
| --- | --- |
| Home, navigation, settings | Working |
| Board rendering and moves | Working |
| Quick pairing / online play | Working |
| WebSocket connection and reconnect flow | Working in tested flows |
| Puzzles and puzzle themes | Working after HarmonyOS-specific fallback fixes |
| Analysis board | Working |
| Local Stockfish / offline computer | Working on emulator and real arm64 device after cross-compiling native libraries |
| SQLite native library | Bundled for x86_64 and arm64 |
| User profiles, watch, studies, tournaments | Working in tested flows |
| In-app browser for ordinary links | Working via ArkWeb PlatformView |
| OAuth login | Implemented; currently opened in the system browser on HarmonyOS because Cloudflare verification did not pass reliably in ArkWeb |
| App icon / splash / app name | Adapted for HarmonyOS |

Known limitations:

| Area | Limitation |
| --- | --- |
| Push notifications | Not implemented. Firebase is skipped on HarmonyOS; this would likely need Huawei Push Kit or another strategy. |
| Release distribution | Not set up. Current builds use local/debug signing. AppGallery release or test distribution would need proper signing, store metadata, and review preparation. |
| OAuth / Cloudflare | Login works best through the system browser. In-app ArkWeb could load pages, but Cloudflare verification was unreliable during testing. |
| OAuth / HMAC secret | The tested private build used `LICHESS_WS_SECRET` via build-time configuration. The public source does not hard-code the working value; I would like guidance from Lichess on the correct official boundary here. |
| AppGallery compliance | Not investigated fully. A public listing may require official developer account ownership, brand/copyright proof, privacy policy alignment, and review-specific material. |
| CI/CD | No HarmonyOS CI is set up. Native libraries are currently built locally. |
| Flutter-ohos maturity | The engine is a community fork, not an official Flutter target. Some rendering/platform behavior may still need device coverage. |

## What changed

The main adaptation areas are:

- `ohos/` platform project for HarmonyOS NEXT
- ArkTS `EntryAbility` integration for Flutter, deep links, URL launching, and PlatformView registration
- ArkWeb-based in-app browser route for ordinary web links
- OAuth handling adjusted so the authorization page can open in the system browser on HarmonyOS while still returning through the custom scheme callback
- HarmonyOS-specific URL launcher shim
- HarmonyOS app resources, icon, splash, app label, and module configuration
- Native library packaging for SQLite and multistockfish on `x86_64` and `arm64-v8a`
- Small Dart compatibility fixes around platform detection, settings UI, puzzle fallback loading, and HarmonyOS-specific plugin availability

Most of the upstream app remains unchanged. The intent is to keep the port mergeable and maintainable against `lichess-org/mobile`, rather than diverging into a separate product.

## Why Flutter-ohos instead of ArkTS

I also evaluated a native ArkTS rewrite. My current view is that a rewrite would be possible but very expensive:

- chessground would need to be rewritten for ArkUI Canvas and gesture handling
- dartchess rules and FEN/move validation would need a replacement or port
- Riverpod-based state management would need a new architecture
- WebSocket routing, reconnection, ACK logic, game/study/tournament flows would need to be reimplemented
- Lichess localization and assets would need a new pipeline
- Keeping parity with upstream mobile releases would become much harder

The Flutter-ohos port keeps the existing Lichess mobile app mostly intact, which seems much more practical for long-term maintenance. That said, I understand if the Lichess team is uncomfortable depending on an unofficial Flutter engine fork.

## Questions for the Lichess team

I would appreciate guidance on the following:

1. Would HarmonyOS NEXT support be interesting to the Lichess project?
2. If yes, would you prefer:
   - upstreaming the HarmonyOS platform files into `lichess-org/mobile`,
   - maintaining a separate repository under the Lichess organization,
   - or keeping this as an external community fork?
3. What would be acceptable regarding the Lichess name and logo while this is not officially released?
4. If this ever moves toward AppGallery distribution, would Lichess want to publish it under the official Lichess developer account, or should a community build use separate branding?
5. Are there concerns around OAuth, HMAC token signing, API usage, or anti-abuse policy that I should address before sharing wider test builds?
6. Would the team be open to reviewing a draft PR or technical document before any public release?

## What I can maintain

I am willing to continue maintaining the HarmonyOS platform work, including:

- Flutter-ohos platform glue
- ArkTS native code
- HarmonyOS packaging and signing documentation
- Stockfish / SQLite native library builds
- AppGallery testing preparation
- keeping the port rebased against upstream mobile
- documenting known HarmonyOS-specific issues

I do not want to make assumptions about branding, repository ownership, or distribution before hearing the team's view. I am happy to adjust the name, logo, README, and distribution language according to the path the Lichess team considers appropriate.

## Repository / demo

Code: https://github.com/RV64G/harmonyos-next

Suggested attachments:

- short demo video: launch -> login -> online play -> puzzle -> analysis -> local Stockfish
- screenshots on a real HarmonyOS NEXT phone
- list of modified files
- notes about debug vs release signing

Thank you for considering this. I am happy to discuss on GitHub, Discord, or wherever is best for the team.

---

## 发送前准备

- [x] 推一个公开 GitHub fork，账号 `rv64g`，分支名建议 `harmonyos-next`。
- [x] 写清楚 GPL-3.0 继承关系，保留 `LICENSE` 和 `COPYING.md`。
- [x] README 顶部写清楚当前是 HarmonyOS NEXT platform experiment/prototype，等待 Lichess 团队指导品牌与分发边界。
- [x] 公开仓库里避免对品牌、上架主体、官方发布身份做超出 Lichess 团队确认范围的承诺。
- [ ] 录制演示视频：启动 -> 登录 -> 在线对局 -> 谜题 -> 分析 -> 本地 Stockfish。
- [ ] 截图真实 HarmonyOS NEXT 手机，不只用模拟器。
- [x] 准备一个修改文件清单，说明哪些是 HarmonyOS 平台文件，哪些是上游兼容修复。
- [x] 准备回答：为什么不用 ArkTS、如何同步上游、Flutter-ohos 风险、AppGallery 如何分发、Push 如何做。
