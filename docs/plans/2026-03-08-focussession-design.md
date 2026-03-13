# FocusSession macOS 设计文档

## 1. 目标

本项目要构建一个以 `Session` 为体验参照、但采用 clean-room 方式实现的本地优先 macOS 专注应用。第一版目标不是做一个简化番茄钟，而是尽量逼近原版的完整体验，包括专注/休息状态机、项目与分类、菜单栏、统计分析、日历集成、快捷指令、桌面组件、背景音效、自动化，以及网站和应用屏蔽。这里的“逼近”指的是功能覆盖、交互节奏和桌面原生体验尽量贴近，而不是复制对方的代码、素材、品牌标识或私有服务接口。

## 2. 非目标

第一版不做账号体系、云同步、多设备同步和服务端分析。本项目按 `macOS 本地完整体验` 设计，所有用户数据默认保存在本机。需要跨浏览器的网站拦截时，采用“本地应用 + 浏览器扩展”的模式；如果未来获得 Apple 的 `Network Extension` entitlement，再把它作为增强层接入，而不是把整个产品架构建立在这一前提上。

## 3. 产品范围

产品范围包括以下模块。`Session Engine` 负责专注、暂停、继续、休息、跳过休息、放弃、延长时长等核心行为。`Projects & Categories` 负责 intention 所属的项目、分类、颜色、默认值、归档和快速选择。`Blocker` 负责应用屏蔽、网站屏蔽、会话期和休息期的差异规则、allow list / deny list、命中日志。`Automation` 负责开始专注、结束专注、开始休息、结束休息时触发本地动作。`Analytics` 负责今日、周、月、自定义区间的统计与趋势。`Calendar` 负责显示日历、将专注记录写回 Apple Calendar，以及从日历上下文快速开始会话。`Shell/UI` 负责主窗口、菜单栏、设置页、统计页、项目页、阻断页、反思弹层、通知与音效。

## 4. 技术路线

整体采用原生 `SwiftUI + AppKit`。SwiftUI 负责主界面、设置、统计和大部分表单；AppKit 负责菜单栏、窗口控制、权限桥接、部分系统通知和需要更细粒度控制的桌面行为。工程以多 target 组织：主 App、登录项 helper、Widget Extension、App Intents Extension、Safari Web Extension，以及共享核心模块。共享核心代码放在本地 Swift Package `Packages/FocusSessionCore` 中，供主 App、Widget、Intents 和扩展共用，避免业务逻辑散落在各 target 中。

为保证工程可重复生成，项目脚手架采用 `XcodeGen`。当前机器有 `Homebrew`，但尚未安装 `xcodegen`，因此实施阶段会先安装该工具，再用 `project.yml` 维护项目结构。这比手写 `.pbxproj` 稳定，也比依赖一次性 GUI 操作更适合后续自动化修改。

## 5. 建议工程结构

建议目录结构如下：

```text
FocusSession.xcodeproj
project.yml
Packages/
  FocusSessionCore/
Apps/
  FocusSessionApp/
  FocusSessionHelper/
Extensions/
  FocusSessionWidget/
  FocusSessionIntents/
  FocusSessionSafariExtension/
BrowserExtensions/
  Chromium/
Resources/
Config/
Tests/
```

其中 `Packages/FocusSessionCore` 放领域模型、状态机、仓储协议、服务协议、统计计算、共享 DTO 和 blocker 规则模型；`Apps/FocusSessionApp` 放主程序 UI 和 App 层编排；`Apps/FocusSessionHelper` 放登录项和后台执行相关逻辑；`Extensions` 目录放 Apple 平台扩展；`BrowserExtensions/Chromium` 放未来 Chromium 浏览器扩展源码；`Resources` 放音效、阻断页静态资源、导出模板等。

## 6. 数据模型

本项目的数据模型按“配置”“运行时状态”“历史记录”三类拆分。配置类模型包括 `Project`、`Category`、`SessionProfile`、`BlockingProfile`、`BlockingRule`、`AutomationRule`、`AppSettings`；运行时状态包括 `ActiveSessionSnapshot`、`BlockerRuntimeState`、`MenubarSnapshot`；历史记录包括 `FocusSessionRecord`、`BreakRecord`、`ReflectionRecord`、`DistractionEvent`、`AnalyticsSnapshot`。建议持久化主数据使用 `SwiftData`，部署目标设为 `macOS 15.0+`，这样可以直接结合 Observation 和现代 SwiftUI 数据流；需要跨 target 快速共享的轻量运行时配置，则同步到 `App Group` 容器中的 JSON 快照。

之所以采用这两层存储，是因为 Widget、App Intents、helper 和 Safari 扩展只需要读取少量稳定配置与当前会话快照，不适合都直接依赖完整数据库读写。主库负责完整历史与可查询性，共享快照负责扩展和后台快速消费。

## 7. 会话状态机

会话引擎必须采用显式有限状态机，而不能依赖零散的布尔字段。核心状态定义为 `idle`、`focusing`、`focusPaused`、`breakRunning`、`breakPaused`、`completed`、`abandoned`。事件定义为 `startSession`、`pause`、`resume`、`extend(minutes)`、`finishFocus`、`startBreak`、`skipBreak`、`finishBreak`、`abandon`、`editMetadata`。所有副作用都挂在状态迁移上：开始专注时写入当前快照、开启 blocker、启动音效、刷新菜单栏、发出通知；进入休息时切换 blocker profile、记录 focus 结束时间、刷新统计中间态；结束或放弃时写入历史记录、触发 reflection、清空活动快照、刷新组件和快捷指令。

这种做法的好处是菜单栏、Widget、App Intents、通知、音效、统计和 blocker 都只需要监听统一状态，而不需要每个界面单独维护一套逻辑。

## 8. 屏蔽系统设计

`App Blocker` 与 `Website Blocker` 统一由 `BlockerCoordinator` 编排，但底层 provider 分离。`AppBlockProvider` 使用 `NSWorkspace` 监听前台应用变更，结合 Accessibility 与 Automation 权限执行策略：警告、切回、隐藏、终止、记录命中事件。`WebsiteBlockProvider` 采用多 provider 设计：Safari 通过 `Safari Web Extension` 实现，Chromium 浏览器通过独立 companion extension 实现，系统级网络过滤通过 `Network Extension` 预留接口但不作为首个可用路径。阻断命中后统一展示本地阻断页，说明当前会话、剩余时间、允许列表提示、快速返回专注入口。

这种设计是有意识地规避单点失败。Apple 官方文档表明 `Network Extension` entitlement 需要额外批准，因此如果把全局网站拦截完全建立在这一能力上，产品交付风险会过高。Provider 化之后，我们可以先交付真正可用的 Safari + 应用阻断，再逐步增强其他浏览器或系统级过滤。

## 9. 系统集成

系统集成包括以下几部分。`SMAppService` 用于注册登录项 helper，实现开机启动和后台常驻。`App Intents` 用于支持开始专注、暂停、继续、上下文动作、获取今日或本周总专注时长。`WidgetKit` 提供当前会话组件和快速开始组件。`UNUserNotificationCenter` 负责开始、即将结束、结束、休息超时等通知。`EventKit` 负责 Apple Calendar 读取与可选写回。`NSStatusItem` 负责菜单栏。音效系统负责开始提示音、休息结束音、成就音和背景白噪音。权限申请遵循按需策略，只在用户第一次启用对应能力时申请。

## 10. 主界面与交互

主窗口采用三栏桌面布局，但视觉上保持轻量。左侧是导航，包含 `Current Session`、`Timeline`、`Projects`、`Analytics`、`Blocker`、`Automation`、`Settings`。中间是主工作区，在首页展示大号环形计时器、intention、project/category、时长编辑、状态按钮。右侧是上下文区域，用于显示今日统计、blocker 状态、白噪音开关、近期分心事件、快捷操作。菜单栏必须可以独立完成高频操作，包括开始、暂停、继续、跳过休息、结束、查看剩余时间和打开主窗口。

开始会话的交互必须足够快：用户输入 intention，可选选择 project/category 和 duration，其余配置由 profile 自动带出。会话结束后弹出轻量 reflection，而不是硬性长表单。统计页支持 `Today / Week / Month / Custom` 四种视图，展示总时长、平均时长、分类分布、日历热图、时段分布、分心事件和项目排行。

## 11. 测试策略

测试从第一天开始分层建设。`FocusSessionCore` 中的状态机、统计计算、规则匹配、导出序列化要有单元测试；`SwiftData` 持久化层要有 repository 测试；菜单栏、主页面主要流程、设置页关键分组要有 UI smoke test；应用阻断和网站阻断需要单独的集成测试与人工验证清单；登录项、Widget、Intents 和 Safari 扩展需要最低限度的联调验证脚本。由于 blocker 和权限流是最大风险点，测试计划要优先覆盖这些模块。

## 12. 风险与缓解

最大风险有四个。第一，系统级网站阻断受 Apple entitlement 限制，因此 blocker 必须 provider 化。第二，辅助权限与自动化权限可能影响应用阻断效果，因此要做好首次引导、状态检测和降级提示。第三，多 target 数据共享如果过度耦合，会导致扩展和主程序读写混乱，因此必须区分主数据库与共享快照。第四，工程目标多、系统集成多，如果没有稳定脚手架会导致变更困难，因此要在最早阶段把 `XcodeGen + 本地 Swift Package` 定下来。

## 13. 当前确认的关键约束

- 目标是尽量逼近 `Session` 的完整体验，而不是做精简版。
- 第一版只做 `macOS 本地完整体验`，不做账号和云同步。
- 第一版必须包含网站和应用屏蔽。
- 实现方式采用原生 `SwiftUI + AppKit`，按完整产品架构分层交付。
- 当前机器具备 `Xcode 26.2`、`Swift 6.2.3` 与 `Homebrew`，但尚未安装 `xcodegen`。

## 14. 下一步

下一步进入实施计划阶段，优先完成可重复生成的工程脚手架、共享核心模块、状态机、主页面骨架、菜单栏和 blocker 基础设施，然后逐步补齐 Safari 扩展、统计、日历、App Intents、Widget 与设置页。
