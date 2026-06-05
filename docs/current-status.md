# 当前状态

## 版本

| 组件 | 版本 |
|------|------|
| Flutter-ohos | 3.41.10-ohos-0.0.1-canary1 |
| Dart | 3.11.1 |
| Lichess Mobile | v0.24.1 |
| DevEco Studio | 6.1.1.280 |
| HarmonyOS SDK | API 24 |

## 功能状态

### ✅ 已验证

| 功能 | 说明 |
|------|------|
| 首页浏览 | Blog 轮播、Tournament、图片加载正常 |
| OAuth 登录 | PKCE 全链路 + HMAC 签名 + 登出 + 重登；公开源码不硬编码可用 secret |
| 快速配对/对弈 | WebSocket 实时通信、棋盘渲染、走棋 |
| 分析棋盘 | 云端引擎分析可用 |
| 本地 Stockfish / 人机对弈 | x86_64 模拟器、arm64 真机均已可用 |
| SQLite 原生库 | x86_64、arm64-v8a 均已打包 |
| 谜题 | 每日谜题 + 主题批量加载、超时兜底 |
| 搜索玩家 | API 请求 + 用户资料浏览 |
| 观战列表 | 直播列表 + 图片加载 |
| 研究棋谱 | Study socket + mine/likes/hot 列表 |
| Tournament | 比赛浏览 + WebSocket 聊天 |
| WebSocket | 连接、Ping/Pong、自动重连、多路由切换 |
| 应用内浏览器 | 普通链接通过 ArkWeb PlatformView 在应用内打开 |

### ⚠️ 有已知限制

| 功能 | 限制 | 原因 |
|------|------|------|
| 谜题 dashboard | 统计图表无数据 | 新账户无 puzzle 历史，API 返回 404（已加 catchError） |
| 观战直播退回 | 偶尔崩溃 | Flutter-ohos CustomPainter GPU 资源回收 bug |
| OAuth 授权页 | HarmonyOS 上改走系统浏览器 | ArkWeb 中 Cloudflare 验证不稳定 |
| Release 分发 | 尚未准备 | 当前为本地 debug signing，需 release/test 签名与 AppGallery 流程 |
| 模拟器稳定性 | 偶尔随机崩溃 | QEMU 虚拟化限制（内存/GPU/网络） |

### ❌ 不可用

| 功能 | 原因 |
|------|------|
| 推送通知 | Firebase 不可用，需 HMS Push Kit 适配 |
| 棋盘动画（部分） | Flutter-ohos 渲染引擎 bug |
| iOS Widget | HarmonyOS Form Kit 未实现 |
| Sign in with Apple/Google | 仅保留 Lichess OAuth |

---

# 修改文件清单

## 上游兼容性修复（不改逻辑）

| 文件 | 修改 | 原因 |
|------|------|------|
| `lib/src/theme.dart` | `Theme.of(context).platform` → `defaultTargetPlatform` | HarmonyOS 上 Theme 推断失败 |
| `lib/src/app.dart` | 同上 + 添加 foundation import | 同上 |
| `lib/src/view/account/account_menu.dart` | 同上 + 添加 foundation import | 同上 |
| `lib/src/view/settings/settings_screen.dart` | 同上 + 添加 foundation import | 同上 |
| `lib/src/network/http.dart` | `makeUserAgent` 参数 `BaseDeviceInfo?` | ohos device_info 可能为 null |
| `lib/src/widgets/expanded_section.dart` | `SizeTransition` 用 `Align` 包裹 | Dart 3.11+ API 变更 |
| `pubspec.yaml` | SDK `>=3.11.0 <4.0.0`，Flutter 约束注释，meta 1.18.2 override | Dart 3.11.1 兼容 |

## HarmonyOS 平台适配

| 文件 | 修改 | 原因 |
|------|------|------|
| `lib/main.dart` | Firebase 跳过、SharedPreferences 注入、PackageInfo mock、ohos 初始化 | 平台功能替代 |
| `lib/src/binding.dart` | Firebase Messaging/Crashlytics guard；Stockfish 使用 HarmonyOS native library path | 无 Firebase 原生实现，Stockfish 已补 native libs |
| `lib/src/init.dart` | Firebase crashlytics try-catch | 保护启动流程 |
| `lib/src/model/common/preloaded_data.dart` | `_OhosDeviceInfo` + `MissingPluginException` catch | device_info 无 ohos 实现 |
| `lib/src/model/auth/auth_controller.dart` | `state = authUser` 移到 `await` 之前、跳过 post-login 服务 | Riverpod autoDispose 时序 |
| `lib/src/model/auth/auth_repository.dart` | `_signingIn` 锁、已登录跳转保护、`closeInAppWebView` try-catch | 并发登录防护 |
| `lib/src/network/connectivity.dart` | `isOnline()` ohos 直接返回 true、`_isLikelyOhos()` | 避免 HEAD 请求崩溃模拟器 |
| `lib/src/model/puzzle/puzzle_providers.dart` | 超时兜底、catchError | 避免瀑布流加载卡死 |
| `lib/src/model/game/game_history.dart` | 网络优先策略 | 提升 HarmonyOS 首次加载稳定性 |
| `lib/src/app_links_service.dart` | ohos 深层链接双订阅 | `dart.library.ohos` 检测失效 |
| `lib/src/constants.dart` | 生产 HMAC 密钥、生产服务器地址 | 生产认证 |
| `lib/src/utils/ohos_stubs.dart` | `OhosConnectivityPlatform`、`initOhosDeepLinks()`、URI 去重 | 统一 ohos 适配层 |

## HarmonyOS 原生代码（ArkTS）

| 文件 | 内容 |
|------|------|
| `ohos/entry/src/main/ets/entryability/EntryAbility.ets` | Flutter engine、PlatformView、url/deep link plugin 注册 |
| `ohos/entry/src/main/ets/plugins/UrlLauncherPlugin.ets` | URL launcher shim；普通链接进应用内浏览器；OAuth 外跳系统浏览器 |
| `ohos/entry/src/main/ets/platform/LichessBrowserPlatformView.ets` | ArkWeb PlatformView |
| `ohos/entry/src/main/module.json5` | 深层链接 scheme `org.lichess.mobile`、启动页、权限 |

## 构建配置

| 文件 | 内容 |
|------|------|
| `ohos/build-profile.json5` | 本地签名配置；公开前必须移除本机 signing material |
| `ohos/entry/libs/**` | x86_64 / arm64-v8a SQLite、multistockfish、libc++ shared libraries |

## 未修改的核心文件（700+）

核心网络协议、WebSocket、棋盘交互、状态管理和大部分 UI 仍沿用上游实现。HarmonyOS 改动集中在平台桥接、原生库打包、少量兼容性修复和已发现问题的兜底处理。
