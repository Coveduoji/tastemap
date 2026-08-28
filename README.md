# TasteMap · 品味地图

> 把你喜欢的地方，钉在地图上。

极简个人地点收藏工具 —— 用地理位置组织自己的记忆与品味。**不做**推荐 / 社交 / 广告 / 账号，数据 100% 来自用户本地。

## 当前状态

P0 核心闭环已实现并可编译运行：

- ✅ 地图首页（flutter_map + OpenStreetMap 全屏，浮动 UI，无底部 Tab）
- ✅ 收藏流程（点「+」→ 附近地点列表 → 填标签/备注/打卡状态 → 保存）
- ✅ Pin 详情 + 具名删除二次确认
- ✅ 导航选择器（高德 / Google / Apple / 拷贝地址）
- ✅ Profile（统计 + 收藏格 + 城市足迹）+ 设置页
- ✅ SQLite 本地持久化（重启数据不丢）
- ✅ 边界情况：定位被拒降级默认坐标、空态引导、筛选空提示、写失败提示

POI 搜索暂用内置示例数据 + 手动输入降级（未接入 Foursquare API key）。

## 技术栈

| 模块 | 方案 |
|------|------|
| 框架 | Flutter + Dart |
| 地图 | flutter_map + OpenStreetMap |
| 本地存储 | sqflite（SQLite） |
| 状态管理 | provider |
| 定位 | geolocator |
| 导航跳转 | url_launcher |

## 运行

```bash
flutter pub get
flutter run              # Android 真机 / 模拟器
flutter run -d chrome    # Web 快速预览
flutter test             # 数据层单测
flutter analyze          # 静态检查
```

## 目录结构

```
lib/
  theme/        # 设计令牌（色彩 / 字体）
  models/       # Place / Collection / CollectionView / PrimaryTag
  data/         # database.dart / collection_repository.dart / mock_pois.dart
  state/        # collection_provider.dart（Provider）
  screens/      # map / profile / settings
  widgets/      # pin_marker / poi_sheet / detail_sheet / nav_picker ...
  utils/        # uuid / 日期格式化
```

## 设计文档

- `TasteMap_Design.html` / `.md` —— 产品设计规范（设计系统、5 界面、关键决策 DDR-01~08）
- `TasteMap_PRD_v1.0.docx` —— 产品需求文档（数据模型、P0/P1/P2 功能清单、验收标准）
- `产品立项.pdf` —— 立项书

## 后续路线（P1 / P2）

图片附加、地图聚合、二级标签、坚果云 WebDAV 同步、埋点日志、城市视图折叠、打卡时间、Foursquare 真实 POI 接入、iOS 打包（Codemagic）。
