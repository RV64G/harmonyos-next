Checkpoint: before OHOS in-app browser

Date: 2026-06-04
Branch: main

Confirmed state:
- Settings background picker works on OHOS.
- Puzzle waterfall fallback works.
- Local Stockfish works on the x86_64 emulator with bundled `libmultistockfish_variant.so`
  and `libc++_shared.so`.
- PING was temporarily changed to show an in-app popover on OHOS, avoiding the external
  browser crash path.
- Current HAP built successfully:
  `build/ohos/hap/entry-default-signed.hap`
  LastWriteTime: 2026-06-04 22:27:56

Known issue motivating next work:
- External browser launch through the OHOS `url_launcher` shim can break the emulator/app
  when the browser card is closed from recents and the user returns to lichess.

Next objective:
- Implement an OHOS in-app browser path with ArkWeb/WebView.
- Prefer in-app browsing for regular links, account links, login/OAuth, and PING.
- Keep external browser only as a fallback if an in-app path cannot support a specific flow.
