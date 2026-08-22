# Dark Mode Switch Button

一个面向 iOS 17+ 的 SwiftUI 演示项目。当前页面展示更鲜明的日夜切换风格，
并把开关作为真正的 App 外观控制使用；Swift Package 同时保留原有视觉风格。

| Light | Dark |
| --- | --- |
| ![Light mode](artifacts/light-mode.png) | ![Dark mode](artifacts/dark-mode.png) |

## 项目简介

这个实现不依赖图片、Lottie 或第三方动画库。云层、星星、太阳、月亮、光环、
边框和阴影全部由 SwiftUI `Shape`、`Canvas`、渐变与视图组合完成。

项目被拆成两个 private GitHub 仓库：

- [DarkModeSwitchButton](https://github.com/HideOnBushTuT/DarkModeSwitchButton)：
  iOS App 壳、Xcode 配置、UI 测试、截图和项目说明。
- [DarkModeToggle](https://github.com/HideOnBushTuT/DarkModeToggle)：
  独立 Swift Package，保存组件源码、几何/素材测试和版本 Tag。

在 Package 新风格审核期间，这个 App 分支暂时锁定远程
`codex/vivid-toggle-style` 分支的提交 `d3f7819`。Package 发布新语义化版本后，
App 会在最终集成前恢复为版本依赖；Clone 后不需要复制组件源码。

## 运行环境

- iOS 17.0+
- iPhone 目标（`TARGETED_DEVICE_FAMILY = 1`）
- 支持 Swift 6.1 Package manifest 的 Xcode/Swift toolchain
- 对两个 private 仓库均有访问权限的 GitHub 账号
- 可选：XcodeBuildMCP，用于 README 中的命令行构建和测试

`DarkModeToggle` Package 同时声明 macOS 14+，目的是让它可以脱离 App 工程
独立编译和运行纯数据测试；本仓库的 App 仍然只面向 iPhone。

## 获取与运行

### 1. 配置 private Package 权限

在 Xcode 的 **Settings → Accounts** 中登录有权限的 GitHub 账号。也可以先
使用 GitHub CLI 配置 Git 凭据：

```bash
gh auth status
gh auth setup-git
```

private 仓库在未认证时经常表现为 `404`，这不代表 URL 写错。

### 2. Clone App

```bash
gh repo clone HideOnBushTuT/DarkModeSwitchButton
cd DarkModeSwitchButton
```

### 3. 在 Xcode 运行

打开 `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj`。

选择 `DarkModeSwitchDemo` Scheme 和一个 iPhone Simulator，然后 Run。
Xcode 会读取 `Package.resolved` 并下载
`https://github.com/HideOnBushTuT/DarkModeToggle.git` 的
`codex/vivid-toggle-style` 分支。

使用 XcodeBuildMCP 构建：

```bash
xcodebuildmcp simulator build \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

## 两仓库架构

```text
DarkModeSwitchButton (App repo)
├── DarkModeSwitchDemo/
│   ├── Config/                          # Bundle、版本、iOS 目标配置
│   ├── DarkModeSwitchDemo/
│   │   ├── DarkModeSwitchDemoApp.swift  # @main App 入口
│   │   ├── ContentView.swift            # 状态、页面布局与 App 外观
│   │   └── DarkModeSwitchDemo.xctestplan
│   ├── DarkModeSwitchDemoUITests/       # App 集成与持久化测试
│   ├── DarkModeSwitchDemo.xcodeproj/
│   │   └── …/Package.resolved           # 依赖版本锁
├── artifacts/                           # Light/Dark 运行截图
├── docs/superpowers/                    # 设计与实施记录
├── README.md
└── THIRD_PARTY_NOTICES.md

DarkModeToggle (Package repo)
├── Package.swift
├── Sources/DarkModeSwitchDemoFeature/
│   ├── DarkModeToggle.swift
│   ├── DarkModeToggleInteraction.swift
│   ├── DarkModeToggleMetrics.swift
│   ├── DarkModeToggleArt.swift
│   ├── VividToggleArt.swift
│   ├── VividToggleTrack.swift
│   ├── DayScene.swift
│   ├── NightScene.swift
│   ├── CelestialThumb.swift
│   └── FourPointStar.swift
├── Tests/DarkModeSwitchDemoFeatureTests/
├── README.md
└── THIRD_PARTY_NOTICES.md
```

App Target 保持很薄：

```swift
import SwiftUI

@main
struct DarkModeSwitchDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

App 本地 `ContentView.swift` 导入 `DarkModeSwitchDemoFeature` 并组合
`DarkModeToggle`。远程 Package 只提供可复用组件，不再决定 App 如何持久化
状态、绘制页面背景或应用明暗外观。仓库名是 `DarkModeToggle`，Product/
`import` 名暂时保留原模块名称，避免仅为发布而产生公开 API 重命名。

## SwiftUI 状态流

核心状态只有一个 Bool：

```swift
@AppStorage("isDarkMode") private var isDarkMode = false

DarkModeToggle(vividIsDarkMode: $isDarkMode)
    .preferredColorScheme(isDarkMode ? .dark : .light)
```

数据流如下：

```text
UserDefaults
    ⇅ @AppStorage("isDarkMode")
ContentView (App repository)
    ├── Binding<Bool> ⇄ DarkModeToggle 的已提交明暗端点
    ├── preferredColorScheme ──→ 整个 WindowGroup 的 Light/Dark 外观
    └── screenBackground ──→ 演示页背景色

DarkModeToggle (Package repository)
    ├── Tap / VoiceOver ──→ 切换 Binding<Bool>
    └── DragGesture ──→ 0...1 呈现进度 ──→ 预测终点 ──→ Binding<Bool>
```

- `@AppStorage` 让状态在 App 重启后保留。
- `@Binding` 让组件不拥有业务状态，可以接入 `@State`、`@AppStorage`
  或其他单一数据源。
- `.preferredColorScheme` 把开关值真正应用到 App，而不只是播放一段动画。
- `isDarkMode` 只保存最终端点；拖动中的画面由 Package 内部连续进度驱动。
- 松手才把预测终点写回 Binding，不需要计时器协调状态。

## 交互与动画组件拆解

```text
DarkModeToggle
├── Button + accessibility + DragGesture
├── DarkModeToggleInteraction
│   └── 方向、进度、钳制与预测终点
├── DarkModeToggleVisuals
│   └── 可中断的当前呈现进度
├── VividToggleTrack
│   ├── RoundedRectangle 背景、外边框与 3 层移动光环
│   ├── VividDayScene
│   │   └── 2 组 Canvas 云层
│   └── VividNightScene
│       └── 6 颗缩放闪烁的 FourPointStar
└── CelestialThumb
    ├── VividSunDisc
    └── VividMoonDisc + 3 个环形山
```

调用 `DarkModeToggle(isDarkMode:)` 仍会进入原有 `ToggleTrack`、`DayScene`、
`NightScene`、`SunDisc` 和月牙绘制路径；新 Demo 只通过不同初始化方式选择新风格。

### 1. 自适应几何

`DarkModeToggle` 外层使用 `GeometryReader` 读取实际宽度，
`DarkModeToggleMetrics` 再把源设计坐标统一缩放：

```swift
var trackScale: CGFloat {
    width / Self.trackArtboard.width
}

var celestialScale: CGFloat {
    width * Self.celestialWidthMultiplier / Self.celestialArtboard.width
}
```

这比逐个写死最终像素更重要：组件保持源设计的相对位置，同时允许调用方通过
`.frame(width:)` 改变整体大小。

### 2. 轨道与场景切换

轨道由连续圆角矩形、外边框渐变和阴影构成。三层半透明光环跟随天体中心移动。
`VividDayScene` 与 `VividNightScene` 同时存在，通过透明度与纵向位移交叉切换，
再使用与轨道相同的 `RoundedRectangle` 遮罩裁切，保证云和星星不会越过边缘。

`.drawingGroup()` 将组合后的轨道离屏合成，减少复杂遮罩与渐变在动画过程中的
重复栅格化边缘问题。

### 3. 云层

`VividToggleArt.cloudGroups` 保存两组源数据，每组由 6 个圆组成。
`CloudGroupView` 使用 `Canvas` 按坐标和半径画白色圆，多个圆叠成云团。

两组云使用相同的 Y 方向位移但不同周期，并开启
`repeatForever(autoreverses: true)`，因此不会完全同步，画面更自然。

### 4. 星星

6 颗星星以坐标、半径和动画组编号存储。`FourPointStar` 是自定义 `Shape`，
沿 8 个外/内顶点生成四角星路径。每颗星使用不同的线性往返周期缩放，形成
错开的闪烁节奏。

### 5. 太阳与月亮

太阳和月亮位于同一个 `CelestialThumb` 画板中：

- `VividSunDisc` 使用暖黄色圆形、渐变描边和两层阴影制造发光与立体感。
- `VividMoonDisc` 使用冷色圆形主体、渐变描边和 3 个环形山。
- 两者在状态变化时做透明度交叉淡入淡出，同时整个天体画板横向移动。

### 6. 跟手拖动与吸附

组件保留标准 `Binding<Bool>` API，但内部使用 `0...1` 连续进度：

```text
progress = clamp(startProgress + translationX / translationTravel, 0 ... 1)
```

移动超过 10 pt 且横向位移占主导后，天体位置、太阳/月亮透明度、日夜天空、
边框、云层和星星同时跟随这个进度，不增加隐式滞后动画。松手时使用
`predictedEndTranslation` 推算终点，因此短促滑动也能完成切换；纵向拖动被取消，
不会误触发按钮。弹簧尚未结束时重新拖动，会从屏幕当前呈现位置继续。

## 关键尺寸与动画参数

| 参数 | 数值 |
| --- | ---: |
| 源组件外部尺寸 | `130 × 80` |
| 轨道画板 | `173 × 69` |
| 天体画板 | `173 × 84` |
| 天体层相对轨道宽度 | `1.2×` |
| Light 天体源 X 位移 | `-100` |
| Dark 天体源 X 位移 | `-25` |
| 拖动识别阈值 | `10 pt` |
| 松手/点击吸附 | Spring response `0.35` / damping `0.82` |
| Reduce Motion 自动收尾 | Ease-out `0.2s`，无弹性 |
| 云层 Y 位移 | `+5 → -3` |
| 两组云层周期 | `4.8 / 6.2s` |
| 六颗星星周期 | `3.5 / 4.1 / 4.9 / 5.3 / 3 / 2.2s` |

当组件宽度为 130 pt 时，天体实际从约 `-90.17 pt` 移动到
`-22.54 pt`，行程约 `67.63 pt`。这是因为原始位移还会乘以
`156 / 173` 的天体缩放比例。

新风格的主要配色：

| 元素 | 颜色 |
| --- | --- |
| 日间天空 | `#4685C0` |
| 夜间天空 | `#191E32` |
| 太阳 | `#FFC323` |
| 月亮 | `#C3C8D2` |
| 月亮环形山 | `#96A0B4` |
| 演示页 Light 背景 | `#EBF6FF` |
| 演示页 Dark 背景 | `#424242` |

## Reduce Motion 与无障碍

组件读取 `accessibilityReduceMotion`：

- 手指直接控制期间仍保持 1:1 跟随。
- 点击时天体位置直接到达端点，只保留 `0.2s` 场景交叉淡化。
- 拖动松手后使用 `0.2s` 非弹性收尾。
- 关闭云层漂浮和星星闪烁的无限循环。

按钮向 VoiceOver 暴露：

- Label：`Dark Mode`
- Value：`On` / `Off`
- Hint：双击切换外观
- Identifier：`darkModeToggle`
- Dark 状态增加 `isSelected` Trait

因此视觉层虽然复杂，辅助功能树中仍然只是一个清晰、可操作的按钮。

## 为什么使用独立 SPM

SPM 不是实现动画的必要条件。把所有 Swift 文件直接放进 App Target，同样能
画出完全一致的效果。这里把组件拆成独立仓库，是一个工程组织和发布选择。

主要收益：

- **模块边界清晰**：App 只依赖公开的 `DarkModeToggle`，内部绘制细节不泄漏
  给调用方；`ContentView` 明确保留在 App。
- **独立版本**：通过语义化 Tag 控制组件升级。
- **可复用**：其他有权限的 App 可以直接添加 GitHub Package URL。
- **测试独立**：几何与源素材测试不需要启动演示 App。
- **历史独立**：Package 仓库保留从几何测试、素材数据到动画实现的相关提交。

对应代价：

- private Package 要求 GitHub 身份认证。
- App 与 Package 的改动需要跨仓库协调。
- Package 修改后要提交、打新 Tag，再更新 App 依赖。
- 对只有一个页面的小项目来说，这个结构比单 Target 更复杂。

因此，独立 SPM 适合“组件要复用、独立版本化或独立维护”的场景；若只是一次性
Demo，放在同一仓库的本地 Package 或 App Target 也完全合理。

## 测试策略与命令

### Package：11 项 Swift Testing 测试

Package 测试锁定拖动进度、横纵轴判定、预测终点、源几何、天体位移、原风格
4 组云和 22 颗星数据、新风格 2 组云和 6 颗星数据，以及 `ContentView` 不会
重新进入 Package 的架构边界：

```bash
gh repo clone HideOnBushTuT/DarkModeToggle
xcodebuildmcp swift-package test \
  --package-path DarkModeToggle \
  --configuration Debug
```

### App：4 项 XCUITest

- 动画尚未结束时快速反向切换，值仍能正确回到 `Off`。
- 切换到 Dark 后终止并重新启动 App，`@AppStorage` 状态仍为 `On`。
- 水平拖动可以进入/退出 Dark，且一次手势只提交一次。
- 纵向拖动不会切换；拖动结束后的下一次点击仍然有效。

```bash
xcodebuildmcp simulator test \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

## 常见编译问题

### Missing package product 'DarkModeSwitchDemoFeature'

先检查 Xcode 是否有 private 仓库权限，然后在 Xcode 中执行：

1. **File → Packages → Reset Package Caches**
2. **File → Packages → Resolve Package Versions**

当前远程依赖记录在 Xcode Project 中；请直接打开 `.xcodeproj`。

### 仓库 URL 返回 404

private GitHub 仓库对未认证请求会隐藏存在性。确认当前账号是
`HideOnBushTuT` 或已被授予仓库权限，并检查：

```bash
gh auth status
git ls-remote https://github.com/HideOnBushTuT/DarkModeToggle.git
```

### Package 分支无法解析

在跨仓库 PR 审核期间，确认远端存在 `codex/vivid-toggle-style` 分支，项目中的
`Package.resolved` 应显示：

- Identity：`darkmodetoggle`
- Branch：`codex/vivid-toggle-style`
- Revision：`d3f7819c1a3058911bf120f8c4cf106b6cfb6529`

这个分支依赖只用于同时审核 Package 与 App。Package 合并并发布后，最终集成前
应把 Xcode Project 改回 `upToNextMajorVersion`，并让 `Package.resolved` 记录
新的语义化版本。不要在 App 仓库中重新创建同名本地 Package 目录。

### Swift tools 版本不兼容

`DarkModeToggle/Package.swift` 使用 `// swift-tools-version: 6.1`。旧工具链
无法读取 manifest 时，请升级到支持 Swift 6.1 的 Xcode/Swift toolchain。

## Git 记录

仓库保留了需求设计、TDD 几何约束、源素材编码、动画实现、App 集成、审查修复、
视觉证明、编译修复和仓库拆分等阶段提交。关键设计与实施记录位于：

- [高保真组件设计](docs/superpowers/specs/2026-08-13-dark-mode-toggle-design.md)
- [SwiftUI 实施计划](docs/superpowers/plans/2026-08-13-dark-mode-toggle-implementation.md)
- [双仓库拆分设计](docs/superpowers/specs/2026-08-13-github-repository-split-design.md)
- [双仓库发布计划](docs/superpowers/plans/2026-08-13-private-repository-split-implementation.md)
- [ContentView 职责迁移设计](docs/superpowers/specs/2026-08-13-content-view-ownership-design.md)
- [ContentView 职责迁移计划](docs/superpowers/plans/2026-08-13-content-view-ownership-implementation.md)
- [3.0 跟手拖动设计](docs/superpowers/specs/2026-08-13-interactive-drag-toggle-design.md)
- [3.0 跟手拖动实施计划](docs/superpowers/plans/2026-08-13-interactive-drag-toggle-implementation.md)

## 设计来源与许可证

原有风格的视觉参考及 Power Apps 实现来自 Kristine Kolodziejski 的
[LightDarkModeAnimated](https://github.com/kristinekolodziejski/LightDarkModeAnimated)；
新风格参考 Xiumuzaidiao 的
[Day-night-toggle-button](https://github.com/Xiumuzaidiao/Day-night-toggle-button)。
两份许可声明均保存在
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
