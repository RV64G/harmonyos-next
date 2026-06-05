# 开发计划：基于 Flutter-ohos

## 技术路线

选择 Flutter-ohos（社区 Flutter 分支）而非完全 ArkTS 重写。
Lichess 700+ Dart 文件，Flutter-ohos 只需适配约 15 个文件，核心逻辑零改动。
与 Lichess 上游保持同步（`git merge upstream/main`）。

## 架构

```
lichess-org/mobile (上游 Flutter 代码，700+ Dart 文件)
  └── lib/src/              ← 不改动
  └── lib/main.dart         ← 入口：ohos stubs 注入
  └── lib/src/binding.dart  ← Firebase stubs + Stockfish native binding guard
  └── lib/src/theme.dart    ← defaultTargetPlatform 适配
  └── lib/src/utils/ohos_stubs.dart  ← 统一的 ohos 平台适配层
  └── ohos/                 ← ArkTS 原生桥接（url_launcher, deep links）
```

## 工作分解

### 第一阶段：环境 + 编译

- 安装 Flutter-ohos canary (Dart 3.11.1)
- 安装 DevEco Studio 6.1.1 + BiSheng JDK 17
- 修改 pubspec.yaml SDK 约束
- 修复 meta 版本冲突
- 首次成功编译 HAP

### 第二阶段：依赖适配

- Firebase → 全 stub（推送/崩溃收集不可用）
- Stockfish → HarmonyOS NDK 交叉编译 `.so`
- SQLite → HarmonyOS `.so` 打包
- SharedPreferences → 内存模拟
- device_info → stub
- PackageInfo → mock
- Connectivity → ohos stub（始终 wifi）
- Theme.of(context).platform → defaultTargetPlatform

### 第三阶段：HarmonyOS 原生功能

- url_launcher：MethodChannel → startAbility 打开系统浏览器
- 深层链接：onNewWant → custom MethodChannel → Flutter → OAuth
- 连通性检测：ohos 上跳过 HEAD 请求

### 第四阶段：OAuth 登录

- HMAC 密钥
- Riverpod autoDispose 时序修复
- ref.mounted 检查移除
- 登出/重登稳定性

### 第五阶段：稳定性打磨

- onNewWant 去重
- OAuth 重复回调保护
- Post-login 服务跳过
- Theme.of(context).platform 全局替换
- 数据库相关 provider 超时兜底
- 游戏历史网络优先策略

### 长期工作（未完成）

- HMS Push Kit 桥接（替换 Firebase 推送）
- 棋盘动画 Flutter-ohos 渲染 bug（等社区修复）
- SharedPreferences 持久化（写入文件系统）
- Release/test signing 与 AppGallery Connect 测试分发

---

# 踩坑记录

## 环境

### 坑 1：Flutter-ohos 版本选择

| 分支 | Flutter | Dart | 结论 |
|------|---------|------|------|
| stable (oh-3.27.0) | 3.27.5 | 3.6.2 | ❌ Dart 太旧 |
| dev (oh-3.35.7) | 3.35.7 | 3.9.2 | ❌ 还是不够 |
| canary (3.41.10) | 3.41.10 | **3.11.1** | ✅ |

canary 的 `version` 文件初始为 `0.0.0-unknown`，需手动改为 `3.41.10-ohos-0.0.1`。

### 坑 2：pubspec.yaml SDK 约束

原始约束 `sdk: ^3.11.5` 在 Dart 3.11.1 不满足。改为 `>=3.11.0 <4.0.0`，Flutter 约束注释掉。

### 坑 3：meta 版本冲突

Flutter SDK 锁定 meta 1.17.0，Lichess 依赖 1.18.0。`dependency_overrides: meta: 1.18.2`。

### 坑 4：code_assets 不识别 ohos

`os.dart` 的 OS 枚举没有 ohos。打补丁：`throw FormatException` → `return OS.linux`。每次依赖升级后需重新打补丁。

### 坑 5：DevEco Studio 路径空格

原指南说路径不能有空格。实测不影响（`D:\DevEco Studio` 和 `D:\DevEcoStudio` 都正常）。

### 坑 6：环境变量配置

必须设置：`JAVA_HOME`、`TOOL_HOME`、`DEVECO_SDK_HOME`、`HOS_SDK_HOME`、`FLUTTER_GIT_URL`。PATH 含 `ohpm\bin`、`hvigor\bin`、`node`、`flutter\bin`。

## Dart 编译

### 坑 7：Freezed 生成代码缺失

首次 `flutter build hap` 100+ 编译错误——`.freezed.dart`/`.g.dart` 未生成。先 `dart run build_runner build`。

### 坑 8：`dart.library.ohos` 环境变量不生效

Flutter-ohos 运行时未设置此变量，`_isOhos` 检测全部失效。替代：`defaultTargetPlatform != 已知平台`。

### 坑 9：`defaultTargetPlatform` 需要显式 import

`package:flutter/foundation.dart` 必须显式导入；widgets.dart/material.dart 在 Flutter-ohos 上可能不重新导出。

### 坑 10：`dart:io` 在字段初始化器崩溃

`app_links_service.dart` 字段初始化时调 `Platform.operatingSystem` 导致白屏——Flutter 绑定未初始化。改在 `start()` 方法中调用。

## 平台功能

### 坑 11：SharedPreferences 无 ohos 实现

注入 `InMemorySharedPreferencesAsync.empty()`。副作用：模拟器崩溃后登录状态丢失。

### 坑 12：PackageInfo.fromPlatform() 卡死

`PackageInfo.setMockInitialValues(...)` 替代。

### 坑 13：device_info_plus MissingPluginException

catch 异常返回 `OhosDeviceInfo` stub。

### 坑 14：Firebase 初始化崩溃

- `main.dart`：条件跳过 Firebase init
- `binding.dart`：`_FirebaseMessagingStub`、`_FirebaseCrashlyticsStub`
- `init.dart`：crashlytics 调用加 try-catch

### 坑 15：`Theme.of(context).platform` 不识别 ohos

`TargetPlatform` 无 ohos 值，抛异常。改为 `defaultTargetPlatform`。影响的文件：`theme.dart`、`app.dart`、`account_menu.dart`、`settings_screen.dart` 等。

### 坑 16：Stockfish 引擎无 ohos native 库

早期通过 stub 保护启动；当前已使用 HarmonyOS NDK 为 x86_64 和 arm64-v8a 交叉编译 `libmultistockfish_variant.so`，本地人机/本地引擎已在模拟器和真机验证。

### 坑 17：SQLite 无 ohos libsqlite3.so

早期数据库路径不可用；当前已打包 x86_64 和 arm64-v8a `libsqlite3.so`。仍需补充可复现构建脚本和 release 构建验证。
早期 `databaseFactory = databaseFactoryFfi` 会触发 dlsym 错误，因此一度禁用本地数据库并让依赖模块回退网络 API；当前打包 native sqlite 后应继续做 release 构建和更多设备验证。

### 坑 18：SizeTransition 缺少 alignment

Dart 3.11+ API 变更。用 `Align` widget 包裹解决。

## 登录与 OAuth

### 坑 19：HMAC 密钥错误

默认 `somethingElseInProd` 不是生产密钥。测试构建可通过 `--dart-define=LICHESS_WS_SECRET=...` 注入；公开源码不硬编码可用 secret，后续需与 Lichess 团队确认官方构建边界。

### 坑 20：onNewWant 覆盖导致崩溃

不能调用 `super.onNewWant(want, launchParam)`——FlutterAbility 内部实现在 ohos 上崩溃。不调 super，自定义 MethodChannel。

### 坑 21：Riverpod autoDispose + ref.mounted

`ref.mounted` 在 authRepository 完成后返回 false，阻止 `state = authUser`。移到所有 await 之前执行。

### 坑 22：OAuth 重复回调

浏览器可能多次触发 `onNewWant`。ArkTS URI 去重 + Flutter handler 去重。

### 坑 23：连通性检测触发模拟器崩溃

HEAD 请求到 gstatic.com/lichess1.org 并发 + app resume 导致 QEMU 崩溃。ohos 上 `isOnline()` 直接返回 `true`。

### 坑 24：登出后再登录卡死

`signIn()` 调 `signOut()` 含网络请求可能阻塞。改为 `state = null` 纯内存操作。

### 坑 25：游戏历史显示"无本机记录"

`onlineStatusProvider` 延迟返回 false 导致走本地 SQLite 路径。修复：网络优先，失败才回退本地。
