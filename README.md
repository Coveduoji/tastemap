# TasteMap · 品味地图

> 把你喜欢的地方，钉在地图上。

极简个人地点收藏工具 —— 用地理位置组织自己的记忆与品味。**不做**推荐 / 社交 / 广告 / 账号，数据 100% 来自用户本地。

## 当前状态

P0 + P1 已实现并在真机跑通：

- ✅ 地图首页（flutter_map + 高德瓦片，全屏、无底部 Tab）
- ✅ 收藏流程（点「+」→ 真实附近地点 → 填标签/备注/打卡状态 → 保存）
- ✅ Pin 详情 + 具名删除二次确认 + 导航选择器
- ✅ Profile（统计 + 收藏格 + 城市足迹）+ 设置页
- ✅ SQLite 本地持久化（重启数据不丢）
- ✅ 二级标签 / 图片附加（压缩 ≤800px）/ 地图聚合 / 城市视图
- ✅ 坚果云 WebDAV 同步（手动备份/恢复 + 后台自动备份）
- ✅ 城市名逆地理编码（顶部显示真实城市/区县）

## 技术栈

| 模块 | 方案 |
|------|------|
| 框架 | Flutter + Dart |
| 地图 | flutter_map + 高德瓦片 |
| POI 搜索 / 逆地理 | 高德 Web 服务 API |
| 本地存储 | sqflite（SQLite） |
| 状态管理 | provider |
| 定位 | geolocator |
| 云同步 | 坚果云 WebDAV（webdav_client） |
| 导航跳转 | url_launcher |

## 配置高德 Key

地图瓦片无需 Key，但 POI 搜索和逆地理需要高德 Web 服务 Key：

1. 复制 `lib/config.example.dart` 为 `lib/config.dart`
2. 把 `amapWebApiKey` 换成你自己的 Key（申请：https://console.amap.com/ ，服务平台选「Web服务」）
3. `lib/config.dart` 已被 `.gitignore` 忽略，不会提交到仓库

## 运行

```bash
flutter pub get
flutter run              # Android 真机 / 模拟器
flutter run -d chrome    # Web 快速预览
flutter test             # 单测
flutter analyze          # 静态检查
```

## 目录结构

```
lib/
  config.dart          # 高德 Key（不入库，见 config.example.dart）
  theme/               # 设计令牌（色彩 / 字体）
  models/              # Place / Collection / CollectionView / PrimaryTag
  data/                # database / repository / poi_search / sync_service
  state/               # collection_provider（Provider）
  screens/             # map / profile / settings / city_list / webdav
  widgets/             # pin_marker / poi_sheet / detail_sheet / nav_picker ...
  utils/               # uuid / 日期格式化 / image_store
```

## 设计文档

- `TasteMap_Design.html` / `.md` —— 产品设计规范（设计系统、5 界面、关键决策 DDR-01~08）
- `TasteMap_PRD_v1.0.docx` —— 产品需求文档（数据模型、P0/P1/P2 功能清单、验收标准）
- `产品立项.pdf` —— 立项书

## 后续路线（P2）

数据统计热力图、二级标签筛选、打卡时间记录、图片批量同步、iOS 打包（Codemagic）。
