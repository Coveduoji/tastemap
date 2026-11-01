<div align="center">
  <img src="assets/app_icons/wander.png" width="112" alt="拾途图标" />
  <h1>拾途</h1>
  <p>把旅行回忆，留在自己的地图里。</p>
  <p>旅行记忆 · 地点收藏 · 私人地图</p>
</div>

拾途是一款用地图保留旅行回忆的 Flutter 应用。把去过的地点、拍下的照片和当时的感受放在一起，再用地图回看自己的足迹。也支持收藏待打卡地点。

目前主要面向 **Android**，处于持续开发阶段。收藏默认保存在本机；地图、地点搜索和定位使用高德服务，也可自行配置 WebDAV 备份。

## 功能

- **地图探索**：原生高德地图、当前位置、地点搜索、附近地点和地点详情。
- **地点收藏**：自定义类型与二级标签、照片、备注，以及已打卡／待打卡状态。收藏列表支持左滑露出删除按钮，确认后删除。
- **足迹概览**：按国家、省、市、区分层聚合，收藏以明黄色圆角星和名称气泡展示。
- **地图与面板联动**：查看收藏时，地图显示地点周边，拖动面板调整地图可见区域。
- **快速查找**：在收藏中按地点、地址、标签或备注搜索。
- **数据管理**：SQLite 本地存储、JSON／CSV 导出、WebDAV 备份与恢复。
- **个性化**：设置中切换“漫游”和“手账”图标，桌面名称始终为“拾途”。
- **开发者联系**：邮箱与 GitHub 问题反馈；微信二维码待补充。

WebDAV 目前备份地点与收藏记录；照片文件的完整跨设备同步仍待完善。

## 开始使用

### 下载预览版

在 [GitHub Releases](https://github.com/Coveduoji/tastemap/releases) 下载 Android ARM64 预览安装包。预览包使用 `com.tastemap.tastemap.preview` 包名，可与原应用并存；两者的本地数据相互独立。

当前预览包仍使用调试证书签名，适合体验与反馈，尚非应用市场正式版本。更新前可先通过设置导出收藏备份。

### 环境

- Flutter 稳定版与 Dart `^3.11.1`；当前已验证 Flutter `3.41.9`。
- 与 Flutter 兼容的 Android SDK、JDK 和 Android 构建环境。
- 高德开放平台账号，以及对应平台的 Key。

### 配置

```bash
git clone https://github.com/Coveduoji/tastemap.git
cd tastemap
cp lib/config.example.dart lib/config.dart
flutter pub get
```

在 `lib/config.dart` 中配置：

| 配置项 | 用途 |
| --- | --- |
| `amapWebApiKey` | 地点搜索、地点详情、逆地理编码等 Web 服务 |
| `amapAndroidApiKey` | Android 原生地图与定位；须匹配安装包名及签名证书 SHA1 |

`lib/config.dart` 已加入 Git 忽略。客户端 Key 仍可能从安装包中被提取，正式分发需结合高德的安全限制和服务端保护方案。

### 构建与安装

```bash
flutter analyze
flutter test
flutter build apk --profile --target-platform android-arm64 --no-tree-shake-icons
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

以上为 ARM64 Android 研发验证包。安装后从桌面“拾途”入口打开。

需要与原安装包并存时，可使用：

```bash
TASTEMAP_PREVIEW=1 flutter build apk --profile --target-platform android-arm64 --no-tree-shake-icons
```

此选项会为应用 ID 增加 `.preview` 后缀；高德 SDK Key 绑定也需对应此包名和证书。不同应用 ID 的本地数据相互独立。

构建 GitHub 分发用的 ARM64 预览包：

```bash
TASTEMAP_PREVIEW=1 flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
```

产物为 `build/app/outputs/flutter-apk/app-release.apk`。工程已配置高德 SDK 的 R8 保留规则。

> 当前 `release` 配置仍使用调试签名。公开发行前需配置长期使用的正式签名；当前研发包不应直接作为市场正式包。

## 项目结构

```text
lib/
├── data/          地点服务、本地数据、导出与备份
├── models/        地点、收藏和标签模型
├── screens/       地图、足迹、搜索和设置页面
├── state/         收藏状态管理
├── theme/         颜色与字体
├── utils/         行政区聚合等业务工具
└── widgets/       地图、标记、表单和拖拽面板
assets/            应用图标及联系渠道资源
design/            图标设计候选原图
android/           Android 工程与系统图标资源
test/              数据、交互与布局测试
third_party/       保留来源与许可证的依赖修复
```

## 技术方案

| 能力 | 主要方案 |
| --- | --- |
| 界面与状态 | Flutter 标准组件、Provider |
| 地图与定位 | 高德地图 SDK、`amap_map`、`amap_location_flutter` |
| 地点服务 | 高德 Web 服务、Dio |
| 本地数据 | sqflite、SQLite |
| 文件与分享 | file_picker、share_plus、image_picker |
| 安全存储与备份 | flutter_secure_storage、webdav_client |
| 应用图标 | flutter_launcher_icons、flutter_dynamic_icon_plus |

开发优先复用标准组件、官方 SDK 和成熟依赖，保持业务实现直接、文案精简。

`third_party/amap_map` 基于 [amap_map 1.0.15](https://github.com/kuloud/amap_map)，保留 Apache-2.0 许可证。当前仅修复两处原生逻辑：摄像机操作接受请求后返回结果，避免 Dart Future 悬挂；定位坐标校验使用纬度而非海拔。上游修复后可移除本地依赖覆盖。

## 验证范围

当前静态检查通过，**35 项自动化测试通过**。覆盖收藏数据、标签管理、搜索、面板拖拽、图标切换、联系邮箱及主要页面布局。

| 场景 | 已检查的逻辑尺寸 |
| --- | --- |
| 小屏与常见手机 | 320×568、360×800、390×844、412×915 |
| 平板尺寸 | 800×1280 |
| 横屏 | 844×390 |
| 放大字体 | 320×720，1.5 倍字体 |

已在连接的 V2417A Android 真机上验证安装、地图与定位、收藏面板、图标切换和开发者联系页面。尺寸测试不等于所有厂商设备、原生地图或键盘场景的真机验证；iPhone、iPad 与折叠屏尚需专项测试。

## 后续计划

- [ ] 丰富地点详情信息源，确认授权、地点匹配和来源标注。
- [ ] 使用成熟认证服务增加注册、登录、退出和注销；完善游客数据迁移、账号隔离与同步。
- [ ] 为左上角城市／区名增加点击功能，具体用途待确定。
- [ ] 补充开发者微信二维码。将准备公开的原图放到 `assets/contact/wechat.png`，重新构建后联系页面自动显示。
- [ ] 补齐 iOS 工程、地图与定位配置、应用图标及签名，并完成 Apple 设备测试。
- [ ] 完善公开发布所需的许可、隐私流程、签名和备案准备。

## 公开发布前

拾途目前是研发预览版本。正式公开分发前，应完成以下准备：

1. **地图授权与配额**：向高德确认公开发行所需的技术服务许可。免费 Key 和测试配额不能直接视为公开上线授权；实际并发量和调用额度以账号控制台为准。[高德 SDK 使用说明](https://lbs.amap.com/api/android-sdk/summary)、[服务计费](https://lbs.amap.com/pages/base_service_price)
2. **地图来源**：备用瓦片接入方式尚需核实公开发行授权，正式版应使用获许可的 SDK／服务，并保留要求的提供方标识。
3. **APP 备案与主体**：根据实际业务、发行地区及个人／企业主体确认备案和渠道资质；软件著作权材料、网站备案和 APP 备案各有用途。[工信部 APP 备案通知](https://www.miit.gov.cn/jgsj/xgj/wjfb/art/2023/art_dd783a581c9644a4aee10afa582811db.html)
4. **隐私与权限**：提供与真实行为一致的隐私说明、第三方 SDK 清单和用户权利入口，核查同意前初始化、拒绝定位、照片选择及 WebDAV 数据流。位置与收藏可能涉及敏感内容。[个人信息保护法](https://www.cac.gov.cn/2021-08/20/c_1631050028355286.htm)
5. **签名与升级**：确定长期包名、正式证书和版本号策略，同步更新高德绑定，验证覆盖升级后收藏保留。[Android 签名指南](https://developer.android.com/studio/publish/app-signing)
6. **品牌与渠道**：核查“拾途”名称及图标的在先权利，按目标渠道当前规则准备截图、介绍、隐私政策链接和版权材料。酷安当前完整准入清单尚未核实，介绍帖、公开下载链接与应用库收录应分别确认。

<details>
<summary>容量、iOS 和账号功能说明</summary>

**Key 能支持多少人？** 它受请求频率与月配额约束，而不是一个固定在线人数。高德当前公开个人认证档列出基础搜索 5,000 次／月、相关接口 QPS 为 3，但不能据此判断本账号的实际剩余额度、授权或有效期。一次地点操作可能产生多次请求，扩大使用前应查看控制台并评估限流与费用。[官方计费说明](https://lbs.amap.com/pages/base_service_price)

**能否提供 iOS 包？** 可以适配，但当前没有应用级 iOS 工程或已验证的 IPA。需要 iOS 平台 Key、Bundle ID、权限配置，以及 macOS、Xcode 和相应签名／分发流程。[Flutter iOS 发行指南](https://docs.flutter.dev/deployment/ios)

**注册登录工作量如何？** 复用成熟认证且服务已配置时，基础邮箱认证约 2–4 人日；包含游客迁移、账号隔离、图片及多端同步的完整方案粗估 2–3 周。实际工作量取决于选定的登录方式与后端，当前尚未实现。

</details>

## 联系与反馈

- 邮箱：<miston.wei@qq.com>
- 问题与建议：[GitHub Issues](https://github.com/Coveduoji/tastemap/issues)

提交问题时请描述复现步骤和应用版本；截图或日志中涉及住址、行程、密钥等内容时，请先做脱敏。

第三方依赖自带的许可证与上游资料保留在各自目录。
