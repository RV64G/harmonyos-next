# ArkTS 重写评估与许可证合规

## 第一部分：ArkTS 重写的技术难点

以下仅描述问题。

### 1. 棋盘渲染

Lichess 的棋盘组件 `chessground` 用 Flutter `CustomPainter` 实现：
- 走棋拖拽（物理模拟、惯性）
- 可选走法高亮（圆点 + 圆形标记）
- 走法箭头绘制
- 将军闪烁动画
- 多种棋盘主题 + 棋子套装动态加载
- 翻转棋盘、坐标标注

ArkUI 的 Canvas API 功能相近但 API 完全不同。整个 chessground 必须从零重写。

### 2. 状态管理

Lichess 用 Riverpod 3.x——高度复杂的响应式状态管理：
- `Provider.autoDispose`
- `.select()` 精细重渲染控制
- `FutureProvider` / `StreamProvider` / `AsyncNotifier`
- `ref.watch` / `ref.listen` / `ref.invalidate`
- Provider 依赖图和循环检测

ArkTS 的 `@State`/`@Prop`/`@StorageLink` 是简单属性绑定，无法替代 Riverpod 的依赖图。需自行开发全局状态管理器。

### 3. 棋规引擎

Lichess 依赖 `dartchess` 包处理所有棋规（合法走法、将军、将死、和棋、FEN 解析）。纯 Dart 代码，ArkTS 无法直接使用。

- FFI 桥接：napi 调 dartchess 不实际（依赖 dart:collection 等 Dart SDK 库）
- 找替代库：ArkTS/Kotlin 社区没有成熟棋规库
- 自写：需要从零实现完整国际象棋规则引擎

### 4. WebSocket 通信层

Lichess 的 WebSocket 协议包含：
- ping/pong 心跳
- ack 消息确认和重发
- 断线自动重连
- 多路由切换（lobby/game/analysis/tournament/study）
- 事件版本协商

ArkTS 有 `WebSocket` API，但以上协议逻辑需全部重写。

### 5. 上游同步

Flutter-ohos 方案通过 `git merge upstream/main` 与 Lichess 官方更新保持同步。ArkTS 重写后，每项新功能需手动跟踪。

### 6. 多语言

Lichess 支持 140+ 语言的 ARB/XML 翻译文件。ArkTS 的 i18n 体系需重新搭建。

### 7. Stockfish 引擎

交叉编译 C++ 到 HarmonyOS NDK——与 Flutter-ohos 方案相同的问题。若已解决 NDK 编译，ArkTS 可直接用 napi 加载。

---

## 第二部分：许可证合规

### Lichess 上游许可证：GPL-3.0

| 要求 | 状态 |
|------|------|
| 保留原始版权声明 | ✅ |
| 修改也必须以 GPL-3.0 开源 | ✅ |
| 分发时必须提供完整源代码 | ✅ |
| 不得附加额外限制 | ✅ |

### HarmonyOS 平台许可兼容

| 组件 | 许可证 | 与 GPL-3.0 兼容 |
|------|--------|-----------------|
| Flutter-ohos | BSD-3-Clause | ✅ |
| DevEco Studio SDK | Huawei 专有 | ✅（仅编译工具） |
| BiSheng JDK | GPL-2.0 + CPE | ✅ |
| OpenHarmony 系统 | Apache 2.0 | ✅ |

### 品牌与商标

"Lichess" 是注册商标。GPL-3.0 许可证不等于商标授权。

- ✅ 声明"基于 Lichess 开源代码"
- ✅ 使用 Lichess API（公开免费）
- ⚠️ 应用名称、logo、上架主体和官方身份应等待 Lichess 团队指导
- ⚠️ 公开分发前需要避免做超出 Lichess 团队确认范围的品牌承诺

当前策略：先作为 HarmonyOS NEXT platform prototype 与 Lichess 团队沟通，询问他们偏好的仓库归属、品牌边界和分发方式。

### 华为 AppGallery 上架要求

| 材料 | 说明 |
|------|------|
| 软件著作权登记证书 | 中国版权保护中心申请 |
| ICP 备案 | 联网应用必须 |
| 隐私政策 URL | 说明数据收集和使用方式 |
| 华为开发者账号 | 实名认证 |

棋类应用通常不需要游戏版号（不同于棋牌博彩类）。涉及积分/排名/竞技系统时咨询审核。

### HMAC 密钥管理

公开源码不硬编码可用密钥，`constants.dart` 使用上游安全默认值。测试构建可通过 `--dart-define=LICHESS_WS_SECRET=...` 注入。

风险：Lichess 可能随时更换密钥；公开/官方构建的密钥注入方式应由 Lichess 团队确认。

推荐通过 `--dart-define` 传入：
```powershell
flutter build hap --dart-define=LICHESS_WS_SECRET=<key>
```

### API 使用合规

| 规则 | 状态 |
|------|------|
| API 用于合法目的 | ✅ |
| 遵守速率限制 | ✅ |
| 不冒充官方客户端 | ⚠️ 需在 User-Agent 标识为第三方 |

---

## 第三部分：ArkTS 重写技术方案

若 Flutter-ohos 不可持续，以下为技术储备。

### 架构

```
ArkTS Lichess Client
  ├── entry/src/main/ets/
  │   ├── pages/           ← 页面
  │   ├── components/      ← 可复用组件（Chessboard 等）
  │   ├── services/        ← API 调用、WebSocket、OAuth
  │   ├── store/           ← 全局状态管理
  │   ├── models/          ← 数据模型
  │   └── i18n/            ← 多语言
  └── entry/src/main/cpp/  ← Stockfish native .so
```

### 关键模块实现

#### Chessboard

ArkUI `Canvas` 组件实现 chessground 视觉效果：
- 棋盘网格：`fillRect` + `strokeRect`
- 棋子：`drawImage`（预加载 SVG/PNG 棋子图片）
- 拖拽：`PanGesture` 事件
- 高亮/箭头：Canvas 路径绘制
- 动画：`animateTo` + `requestAnimationFrame`

#### 状态管理

`@Observed` + `@ObjectLink` + `EventHub` 发布订阅模式替代 Riverpod：
```typescript
@Observed
class AppState {
  authUser: AuthUser | null = null;
  currentGame: GameState | null = null;
  puzzles: PuzzleState = new PuzzleState();
}
```

#### 棋规引擎

- 短期：直接调 Lichess API 端点避免本地棋规计算
- 长期：移植 TypeScript 棋规库（如 chess.js）通过 ArkTS → JS 互操作

#### HTTP 客户端

`@ohos.net.http` 模块：
```typescript
import http from '@ohos.net.http';
const request = http.createHttp();
request.request('https://lichess.org/api/account', {
  method: http.RequestMethod.GET,
  header: { 'Authorization': `Bearer ${token}` }
});
```

#### WebSocket

`@ohos.net.webSocket` 模块实现 Lichess 协议：
```typescript
import webSocket from '@ohos.net.webSocket';
const ws = webSocket.createWebSocket();
ws.connect('wss://socket.lichess.org/socket/v5');
```

### 与 Flutter-ohos 方案的差异

| 维度 | Flutter-ohos | ArkTS |
|------|-------------|-------|
| 与上游 diff | ~15 文件 | 100% 重写 |
| 功能同步 | `git merge` | 手动跟踪 |
| chessground | 直接可用 | 从零实现 |
| dartchess | 直接可用 | 需替代或自写 |
| 第三方依赖 | 桥接 ~5 个插件 | 重写所有依赖 |
| 测试覆盖 | 上游 ~2000 测试 | 从零写 |
| 华为生态 | OpenHarmony SIG | 华为主推 |
| AppGallery 审核 | 开源 Flutter | 原生 ArkTS（可能更易过审） |
