# TasteMap 品味地图 · 项目进展与待办

> 把你喜欢的地方，钉在地图上。

极简个人地点收藏工具 —— 用地理位置组织个人记忆与品味。**不做**推荐 / 社交 / 广告 / 账号，数据 100% 来自用户本地。

---

## 一、当前进展

### P0 核心闭环（已完成）

- 地图首页：flutter_map + 高德瓦片，全屏、无底部 Tab
- 收藏流程：点「+」→ 附近地点 → 填标签/备注/打卡状态 → 保存
- Pin 详情 + 具名删除二次确认（DDR-07）
- 导航选择器（高德 / Google / Apple / 拷贝地址）
- SQLite 本地持久化（重启数据不丢）
- Profile（统计 + 收藏格 + 城市足迹）+ 设置页

### P1（已完成）

- 二级标签（值得二刷 / 氛围好 / 性价比高，多选、选填）
- 图片附加（拍照/相册、最多 3 张、压缩 ≤800px 长边）
- 地图聚合（缩小时邻近点合并为数字气泡，点击放大）
- 城市视图（收藏列表按城市分组折叠）
- 坚果云 WebDAV 同步（手动备份/恢复 + 后台自动备份）

### 真机调优（本轮迭代）

- 地图瓦片 OSM → 高德（国内可访问），默认中心改北京
- 城市名用高德逆地理编码，顶部显示真实城市/区县
- 定位改用系统 LocationManager（绕过国产机损坏的 Google 服务）
- POI 用高德：周边搜索 + **全国关键词搜索**（异地收藏，便于以后去）
- **拖图模式**：收藏弹窗开着时地图可拖动，中心 📍 固定，拖动后以新中心刷新附近地点
- 点搜索结果地图移动到该位置
- Pin 简化为纯 emoji；空态只留 📍；移除顶部筛选按钮
- 收藏弹窗默认半屏、可拖到 3/4 屏

> 核心交互约定：「附近地点」始终以**地图中心（钉子位置）**为准，而非用户真实定位。

---

## 二、技术栈

| 模块 | 方案 |
|------|------|
| 框架 | Flutter + Dart |
| 地图 | flutter_map + 高德瓦片 |
| POI 搜索 / 逆地理 | 高德 Web 服务 API |
| 本地存储 | sqflite（SQLite） |
| 状态管理 | provider |
| 定位 | geolocator（强制系统 LocationManager） |
| 云同步 | 坚果云 WebDAV（webdav_client）+ connectivity_plus |
| 图片 | image_picker + flutter_image_compress |
| 导航跳转 | url_launcher |

### 配置说明

- 高德 Key：复制 `lib/config.example.dart` 为 `lib/config.dart` 并填写（申请：https://console.amap.com/ ，选「Web服务」）。`config.dart` 已被 `.gitignore` 忽略。
- 国内网络：Gradle 走阿里云/腾讯云镜像 + 本地代理（`android/gradle.properties`），Kotlin 进程内编译，跳过 ASCII 路径检查。

---

## 三、待办（TODO）

### 🔴 正确性 / 体验缺陷

1. 收藏时 `country` 字段仍为空（只填了 `city`），可补逆地理的 `province` 或固定「中国」
2. WebDAV 恢复是「全量替换」，多设备冲突（PRD：以 `updated_at` 较新者为准）未做
3. 图片在 Web 端不可用（用了 `dart:io` File，Web 预览会受影响）

### 🟡 P2（后续版本）

4. 数据统计热力图（需 ≥50 个收藏才有意义）
5. 二级标签筛选（依赖二级标签数据积累）
6. 打卡时间记录
7. 图片批量同步

### ⚙️ 工程类

8. release 打包（配签名，体积更小、可直接分发）
9. iOS 打包（需 Mac 或 Codemagic，Windows 无法本地打包）
10. 测试覆盖（目前只有模型层单测，无 widget / integration 测试）
11. 长按「+」拖图标记（PRD P0 遗留；现在拖图模式已覆盖大部分场景，可评估是否需要）

---

## 四、目录结构

```
lib/
  config.dart            # 高德 Key（不入库，见 config.example.dart）
  theme/                 # 设计令牌（色彩 / 字体）
  models/                # Place / Collection / CollectionView / PrimaryTag
  data/                  # database / repository / poi_search / sync_service / sync_manager
  state/                 # collection_provider（Provider）
  screens/               # map / profile / settings / city_list / webdav
  widgets/               # pin_marker / poi_sheet / detail_sheet / nav_picker ...
  utils/                 # uuid / 日期格式化 / image_store
```

---

## 五、设计文档

- `TasteMap_Design.html` / `.md` —— 产品设计规范（设计系统、5 界面、关键决策 DDR-01~08）
- `TasteMap_PRD_v1.0.docx` —— 产品需求文档（数据模型、P0/P1/P2 功能清单、验收标准）
- `产品立项.pdf` —— 立项书
