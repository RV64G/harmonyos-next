# Lichess for HarmonyOS NEXT

> HarmonyOS NEXT platform prototype | 基于 Flutter-ohos（Flutter 的 OpenHarmony 社区分支） | 与上游保持兼容

> **注**：代码中 `ohos` 是 Flutter-ohos 引擎内部的技术标识（目录名、平台检测常量等），用户面均称为 HarmonyOS。

## 快速信息

| 项目 | 详情 |
|------|------|
| 上游仓库 | [lichess-org/mobile](https://github.com/lichess-org/mobile) |
| 许可证 | GPL-3.0（继承上游） |
| 引擎 | Flutter-ohos 3.41.10-canary (Dart 3.11.1) |
| 构建工具 | DevEco Studio 6.1.1 + BiSheng JDK 17 |
| 目标平台 | HarmonyOS NEXT API 24+ |

## 文档索引

| 文档 | 内容 |
|------|------|
| [开发计划 (Flutter-ohos)](development-plan.md) | 架构 + 工作分解 + 25 个踩坑记录 |
| [当前状态](current-status.md) | 功能完成度 + 修改文件清单 |
| [HarmonyOS 修改清单](harmonyos-change-summary.md) | 给 issue/PR review 用的改动摘要 |
| [原生库说明](native-libraries.md) | SQLite / Stockfish HarmonyOS `.so` 来源和构建记录 |
| [分发与签名说明](harmonyos-distribution.md) | HAP、debug 签名、AppGallery 测试路径 |
| [公开仓库检查清单](public-repo-checklist.md) | 推送 `RV64G/harmonyos-next` 前的清理项 |
| [ArkTS 重写评估 + 许可证合规](arkts-feasibility.md) | ArkTS 难点 + GPL-3.0 + AppGallery + ArkTS 技术方案 |
| [GitHub Issue 投稿信](github-issue.md) | 给 Lichess 团队的信 |

## 路线总览

| 路线 | 状态 | 说明 |
|------|------|------|
| Flutter-ohos 移植 | ✅ 已完成 | ~90% 功能可用 |
| WebView PWA 包装 | 未开始 | 网页版套壳，功能完整但无原生体验 |
| ArkTS 重写 | 未开始 | 详见 [ArkTS 重写评估](arkts-feasibility.md) |

## 构建

```powershell
flutter pub get
dart run build_runner build
flutter run -d <ohos_device> --debug
```
