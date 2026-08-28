# TasteMap · 产品设计

> 把你喜欢的地方，钉在地图上。

平台：Android（Flutter）+ 后期 iOS · MVP v1.0 · 2026

---

## 设计系统

### 色彩

| 名称 | Hex | 用途 |
|------|-----|------|
| Ink Black | `#2D2A26` | 主文字 / FAB / 主 CTA |
| Warm White | `#F5F0E8` | 页面背景 / 卡片 |
| Terracotta | `#B8906A` | 强调色 / 高亮 |
| Stone | `#8C8880` | 次要文字 |
| Food Orange | `#E07040` | 🍜 美食 |
| Coffee Brown | `#A07850` | ☕ 咖啡 |
| Hotel Blue | `#4878CC` | 🏨 酒店 |
| Sight Green | `#3A9C58` | 📷 景点 |
| Bar Purple | `#9048B8` | 🍸 酒吧 |

### 字体

- **Noto Serif SC** — 地点名、城市名、Profile 昵称（中文衬线，有温度）
- **DM Sans** — 标签、按钮、距离、时间（无衬线，克制）
- **DM Serif Display** — 品牌 Tagline（仅出现一次）

### Pin 状态

- 已打卡 → 实心底色圆泡
- 待打卡 → 透明 + 虚线边框
- 选中 → `box-shadow: 0 0 0 3px #2D2A26`，scale 1.15

---

## 地图首页

100% 全屏地图，所有 UI 浮动叠加，无底部 Tab Bar。参照高德「附近」的全屏结构，但去掉平台推荐，只显示用户自己的收藏。

**核心决策：Pin 无常驻文字标签。** 用户对自己的收藏有记忆，Emoji 即记忆锚点，点击后才显示 Tooltip。

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>TasteMap · 地图首页</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@700&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#E8E4DC;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:2rem;}
.phone{width:300px;height:640px;border-radius:40px;overflow:hidden;border:2px solid #C8C4BC;box-shadow:0 16px 48px rgba(0,0,0,.18);position:relative;background:#E9E5DC;flex-shrink:0;}
.map-svg{width:100%;height:100%;position:absolute;inset:0;}
.sbar{position:absolute;top:0;left:0;right:0;z-index:30;height:32px;display:flex;align-items:center;justify-content:space-between;padding:0 20px;background:linear-gradient(to bottom,rgba(245,240,232,.7),transparent);}
.sbt{font-size:11px;font-weight:500;color:#2D2A26;}
.top-bar{position:absolute;top:32px;left:0;right:0;z-index:25;padding:8px 14px 0;display:flex;flex-direction:column;gap:7px;}
.top-row{display:flex;align-items:center;gap:8px;}
.city-pill{display:flex;align-items:center;gap:6px;background:rgba(245,240,232,.92);border-radius:20px;padding:5px 13px;backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);cursor:pointer;flex:1;}
.city-name{font-family:'Noto Serif SC',serif;font-size:15px;font-weight:700;color:#2D2A26;line-height:1;}
.city-sub{font-size:9px;color:#8C8880;margin-top:1px;}
.city-caret{font-size:10px;color:#8C8880;margin-left:auto;}
.icon-btn{width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;cursor:pointer;}
.avatar-btn{width:36px;height:36px;border-radius:50%;background:#C4A882;border:2px solid rgba(245,240,232,.9);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;cursor:pointer;}
.filter-row{display:flex;gap:6px;overflow-x:auto;scrollbar-width:none;}
.filter-row::-webkit-scrollbar{display:none;}
.fchip{flex-shrink:0;font-size:11px;font-weight:500;padding:5px 11px;border-radius:18px;backdrop-filter:blur(8px);cursor:pointer;white-space:nowrap;}
.fc-all{background:rgba(45,42,38,.88);color:#F5F0E8;}
.fc-cat{background:rgba(245,240,232,.88);color:#4A4642;border:0.5px solid rgba(45,42,38,.1);}
.nearby{position:absolute;top:0;left:50%;transform:translateX(-50%);background:rgba(45,42,38,.82);color:#F5F0E8;font-size:10px;padding:3px 12px;border-radius:0 0 10px 10px;backdrop-filter:blur(4px);z-index:26;white-space:nowrap;}
.pin{position:absolute;z-index:15;transform:translate(-50%,-100%);display:flex;flex-direction:column;align-items:center;cursor:pointer;}
.pb{width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;box-shadow:0 2px 8px rgba(0,0,0,.18);transition:transform .15s;}
.pb:hover{transform:scale(1.1);}
.pt{width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:8px solid;margin-top:-1px;}
.pb-coffee{background:#EDE0D0;}.pt-coffee{border-top-color:#EDE0D0;}
.pb-food{background:#FFDFC8;}.pt-food{border-top-color:#FFDFC8;}
.pb-sight{background:#D8F0E0;}.pt-sight{border-top-color:#D8F0E0;}
.pb-pend{background:rgba(245,240,232,.85);border:2px dashed #B0AAA0;}
.pt-pend{border-top-color:rgba(200,195,188,.4);}
.pb-sel{box-shadow:0 0 0 3px #2D2A26,0 2px 8px rgba(0,0,0,.22)!important;}
.tooltip{position:absolute;bottom:calc(100% + 8px);left:50%;transform:translateX(-50%);background:#2D2A26;color:#F5F0E8;border-radius:9px;padding:7px 10px;min-width:120px;white-space:nowrap;box-shadow:0 4px 16px rgba(0,0,0,.22);font-size:11px;}
.tt-sub{font-size:9px;color:rgba(245,240,232,.65);margin-top:1px;}
.tt-arr{position:absolute;bottom:-5px;left:50%;transform:translateX(-50%);width:0;height:0;border-left:5px solid transparent;border-right:5px solid transparent;border-top:5px solid #2D2A26;}
.cluster{position:absolute;z-index:14;transform:translate(-50%,-50%);width:32px;height:32px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:12px;font-weight:500;display:flex;align-items:center;justify-content:center;border:2.5px solid #F5F0E8;box-shadow:0 2px 6px rgba(0,0,0,.2);cursor:pointer;}
.locdot{position:absolute;z-index:13;width:14px;height:14px;border-radius:50%;background:#4878CC;border:2.5px solid #F5F0E8;box-shadow:0 0 0 5px rgba(72,120,204,.2);transform:translate(-50%,-50%);}
.fab{position:absolute;bottom:24px;left:50%;transform:translateX(-50%);width:52px;height:52px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:26px;font-weight:300;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 16px rgba(0,0,0,.28);z-index:20;cursor:pointer;transition:transform .15s;}
.fab:active{transform:translateX(-50%) scale(.93);}
.loc-btn{position:absolute;right:14px;bottom:90px;z-index:20;width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:15px;cursor:pointer;}
</style>
</head>
<body>
<div class="phone">
  <svg class="map-svg" viewBox="0 0 300 640" xmlns="http://www.w3.org/2000/svg">
    <rect width="300" height="640" fill="#E9E5DC"/>
    <line x1="0" y1="160" x2="300" y2="160" stroke="#F2EDE4" stroke-width="12"/>
    <line x1="0" y1="320" x2="300" y2="320" stroke="#F2EDE4" stroke-width="10"/>
    <line x1="0" y1="470" x2="300" y2="470" stroke="#F2EDE4" stroke-width="8"/>
    <line x1="80" y1="0" x2="80" y2="640" stroke="#F2EDE4" stroke-width="12"/>
    <line x1="200" y1="0" x2="200" y2="640" stroke="#F2EDE4" stroke-width="10"/>
    <line x1="140" y1="0" x2="140" y2="640" stroke="#EDE8DF" stroke-width="4"/>
    <line x1="0" y1="240" x2="300" y2="240" stroke="#EDE8DF" stroke-width="4"/>
    <line x1="0" y1="395" x2="300" y2="395" stroke="#EDE8DF" stroke-width="4"/>
    <rect x="5" y="5" width="68" height="148" rx="5" fill="#DDD9CF"/>
    <rect x="5" y="170" width="68" height="64" rx="5" fill="#DDD9CF"/>
    <rect x="88" y="5" width="104" height="148" rx="5" fill="#D8D4CA"/>
    <rect x="88" y="170" width="104" height="144" rx="5" fill="#DDD9CF"/>
    <rect x="88" y="328" width="104" height="128" rx="5" fill="#DDD9CF"/>
    <rect x="208" y="5" width="88" height="148" rx="5" fill="#DDD9CF"/>
    <rect x="208" y="170" width="88" height="64" rx="5" fill="#DDD9CF"/>
    <rect x="208" y="248" width="88" height="64" rx="5" fill="#DDD9CF"/>
    <rect x="208" y="328" width="88" height="128" rx="5" fill="#D8D4CA"/>
    <rect x="5" y="328" width="68" height="128" rx="5" fill="#DDD9CF"/>
    <rect x="5" y="478" width="188" height="90" rx="8" fill="#C4D8BC"/>
    <rect x="208" y="478" width="88" height="90" rx="5" fill="#DDD9CF"/>
  </svg>
  <div class="sbar"><span class="sbt">9:41</span><span class="sbt">●●● ▌</span></div>
  <div class="nearby">视野内 · 4 个收藏</div>
  <div class="top-bar">
    <div class="top-row">
      <div class="city-pill"><div><div class="city-name">Tokyo</div><div class="city-sub">晴 · 12°C</div></div><div class="city-caret">▾</div></div>
      <div class="icon-btn">🔍</div>
      <div class="avatar-btn">🐕</div>
    </div>
    <div class="filter-row">
      <div class="fchip fc-all">全部</div>
      <div class="fchip fc-cat">🍜 美食</div>
      <div class="fchip fc-cat">☕ 咖啡</div>
      <div class="fchip fc-cat">📷 景点</div>
      <div class="fchip fc-cat">🍸 酒吧</div>
    </div>
  </div>
  <!-- selected pin with tooltip -->
  <div class="pin" style="left:37%;top:38%;">
    <div class="tooltip" style="font-weight:500;">Fuglen Tokyo<div class="tt-sub">☕ 咖啡 · 已打卡</div><div class="tt-arr"></div></div>
    <div class="pb pb-coffee pb-sel">☕</div><div class="pt pt-coffee"></div>
  </div>
  <div class="pin" style="left:67%;top:26%;"><div class="pb pb-food">🍜</div><div class="pt pt-food"></div></div>
  <div class="pin" style="left:74%;top:53%;"><div class="pb pb-sight">📷</div><div class="pt pt-sight"></div></div>
  <div class="pin" style="left:22%;top:64%;"><div class="pb pb-pend" style="font-size:16px;color:#8C8880;">🍸</div><div class="pt pt-pend"></div></div>
  <div class="cluster" style="left:82%;top:73%;">3</div>
  <div class="locdot" style="left:50%;top:76%;"></div>
  <div class="loc-btn">◎</div>
  <div class="fab">+</div>
</div>
</body>
</html>
```

---

## POI 底部弹层 + 收藏填写

点击 FAB「+」触发，两步共享同一 Sheet 容器，地图始终保持可见。

**列表最多 6 条**（非 PRD 的 10 条）——用户站在门口，目标 90% 在前 2–3 条。点击条目直接切换填写页，无二次确认。

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>TasteMap · POI 弹层</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@700&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#E8E4DC;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;padding:2rem;gap:1rem;}
.hint{font-size:12px;color:#8C8880;}.hint span{background:#2D2A26;color:#F5F0E8;border-radius:8px;padding:3px 10px;font-size:11px;}
.phone{width:300px;height:640px;border-radius:40px;overflow:hidden;border:2px solid #C8C4BC;box-shadow:0 16px 48px rgba(0,0,0,.18);position:relative;background:#E9E5DC;flex-shrink:0;}
.map-layer{position:absolute;inset:0;z-index:1;transition:bottom .36s cubic-bezier(.32,0,.15,1);}
.map-layer.pushed{bottom:62%;}
.map-svg{width:100%;height:100%;}
.sbar{position:absolute;top:0;left:0;right:0;z-index:30;height:32px;display:flex;align-items:center;justify-content:space-between;padding:0 20px;background:linear-gradient(to bottom,rgba(245,240,232,.65),transparent);}
.sbt{font-size:11px;font-weight:500;color:#2D2A26;}
.top-bar{position:absolute;top:32px;left:0;right:0;z-index:25;padding:8px 14px 0;display:flex;flex-direction:column;gap:7px;}
.top-row{display:flex;align-items:center;gap:8px;}
.city-pill{display:flex;align-items:center;gap:6px;background:rgba(245,240,232,.92);border-radius:20px;padding:5px 13px;backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);cursor:pointer;flex:1;}
.city-name{font-family:'Noto Serif SC',serif;font-size:15px;font-weight:700;color:#2D2A26;line-height:1;}
.city-sub{font-size:9px;color:#8C8880;margin-top:1px;}
.city-caret{font-size:10px;color:#8C8880;margin-left:auto;}
.icon-btn{width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;cursor:pointer;}
.avatar-btn{width:36px;height:36px;border-radius:50%;background:#C4A882;border:2px solid rgba(245,240,232,.9);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;cursor:pointer;}
.filter-row{display:flex;gap:6px;overflow-x:auto;scrollbar-width:none;}
.filter-row::-webkit-scrollbar{display:none;}
.fchip{flex-shrink:0;font-size:11px;font-weight:500;padding:5px 11px;border-radius:18px;backdrop-filter:blur(8px);cursor:pointer;white-space:nowrap;}
.fc-all{background:rgba(45,42,38,.88);color:#F5F0E8;}
.fc-cat{background:rgba(245,240,232,.88);color:#4A4642;border:0.5px solid rgba(45,42,38,.1);}
.nearby{position:absolute;top:0;left:50%;transform:translateX(-50%);background:rgba(45,42,38,.82);color:#F5F0E8;font-size:10px;padding:3px 12px;border-radius:0 0 10px 10px;backdrop-filter:blur(4px);z-index:26;white-space:nowrap;}
.pin{position:absolute;z-index:15;transform:translate(-50%,-100%);display:flex;flex-direction:column;align-items:center;}
.pb{width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;box-shadow:0 2px 8px rgba(0,0,0,.18);}
.pt{width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:8px solid;margin-top:-1px;}
.pb-coffee{background:#EDE0D0;}.pt-coffee{border-top-color:#EDE0D0;}
.pb-food{background:#FFDFC8;}.pt-food{border-top-color:#FFDFC8;}
.pb-sight{background:#D8F0E0;}.pt-sight{border-top-color:#D8F0E0;}
.cluster{position:absolute;z-index:14;transform:translate(-50%,-50%);width:32px;height:32px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:12px;font-weight:500;display:flex;align-items:center;justify-content:center;border:2.5px solid #F5F0E8;box-shadow:0 2px 6px rgba(0,0,0,.2);}
.locdot{position:absolute;z-index:13;width:14px;height:14px;border-radius:50%;background:#4878CC;border:2.5px solid #F5F0E8;box-shadow:0 0 0 5px rgba(72,120,204,.2);transform:translate(-50%,-50%);}
.fab{position:absolute;bottom:24px;left:50%;transform:translateX(-50%);width:52px;height:52px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:26px;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 16px rgba(0,0,0,.28);z-index:20;cursor:pointer;transition:transform .15s;}
.fab:active{transform:translateX(-50%) scale(.93);}
.loc-btn{position:absolute;right:14px;bottom:90px;z-index:20;width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:15px;cursor:pointer;}
/* POI SHEET */
.poi-sheet{position:absolute;bottom:0;left:0;right:0;z-index:40;background:#F5F0E8;border-radius:22px 22px 0 0;transform:translateY(100%);transition:transform .36s cubic-bezier(.32,0,.15,1);display:flex;flex-direction:column;max-height:64%;box-shadow:0 -6px 28px rgba(0,0,0,.13);}
.poi-sheet.open{transform:translateY(0);}
.ps-handle{display:flex;justify-content:center;padding:11px 0 5px;flex-shrink:0;}
.ps-bar{width:38px;height:4px;border-radius:2px;background:#D5D0CA;}
.ps-head{padding:0 16px 10px;flex-shrink:0;}
.ps-title-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:3px;}
.ps-title{font-family:'Noto Serif SC',serif;font-size:15px;font-weight:700;color:#2D2A26;}
.ps-close{font-size:18px;color:#8C8880;cursor:pointer;}
.ps-sub{font-size:10px;color:#8C8880;}
.step-ind{display:flex;gap:4px;align-items:center;}
.step-dot{width:6px;height:6px;border-radius:50%;background:#D5D0CA;transition:all .2s;}
.step-dot.active{background:#2D2A26;width:16px;border-radius:3px;}
.ps-search{margin:0 16px 10px;background:#EDE8E0;border-radius:11px;padding:8px 13px;display:flex;align-items:center;gap:9px;flex-shrink:0;}
.pdiv{height:0.5px;background:#E8E2DA;margin:0 16px;flex-shrink:0;}
.poi-list{flex:1;overflow-y:auto;scrollbar-width:none;}
.poi-list::-webkit-scrollbar{display:none;}
.poi-item{display:flex;align-items:center;gap:11px;padding:12px 16px;border-bottom:0.5px solid #ECEAE3;cursor:pointer;transition:background .12s;position:relative;}
.poi-item:hover{background:#EDE8E0;}
.poi-item.selected{background:#F0EBE2;}
.poi-ico{width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;}
.pic-food{background:#FFDFC8;}.pic-coffee{background:#EDE0D0;}.pic-hotel{background:#D8E8FC;}.pic-sight{background:#D8F0E0;}.pic-bar{background:#EDD8F4;}
.poi-name{font-family:'Noto Serif SC',serif;font-size:13px;font-weight:700;color:#2D2A26;margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.poi-meta{font-size:10px;color:#8C8880;}
.poi-dist{margin-left:auto;flex-shrink:0;font-size:11px;font-weight:500;color:#B8906A;}
.poi-check{position:absolute;right:14px;top:50%;transform:translateY(-50%);width:22px;height:22px;border-radius:50%;background:#2D2A26;color:#F5F0E8;display:flex;align-items:center;justify-content:center;font-size:11px;}
.manual-row{display:flex;align-items:center;gap:11px;padding:12px 16px;cursor:pointer;border-top:0.5px solid #E0DAD0;background:#F5F0E8;flex-shrink:0;}
.manual-ico{width:40px;height:40px;border-radius:11px;background:#EDE8E0;display:flex;align-items:center;justify-content:center;font-size:19px;flex-shrink:0;}
.manual-link{font-size:12px;color:#4878CC;font-weight:500;}
/* FORM SHEET */
.form-sheet{position:absolute;bottom:0;left:0;right:0;z-index:50;background:#F5F0E8;border-radius:22px 22px 0 0;transform:translateY(100%);transition:transform .36s cubic-bezier(.32,0,.15,1);display:flex;flex-direction:column;max-height:80%;box-shadow:0 -6px 28px rgba(0,0,0,.13);}
.form-sheet.open{transform:translateY(0);}
.fs-handle{display:flex;justify-content:center;padding:11px 0 5px;flex-shrink:0;}
.fs-bar{width:38px;height:4px;border-radius:2px;background:#D5D0CA;}
.fs-head{padding:0 16px 11px;border-bottom:0.5px solid #E8E2DA;flex-shrink:0;}
.fs-step{font-size:10px;color:#B8906A;font-weight:500;margin-bottom:5px;display:flex;align-items:center;justify-content:space-between;}
.fs-back{font-size:11px;color:#4878CC;cursor:pointer;}
.fs-poi-name{font-family:'Noto Serif SC',serif;font-size:15px;font-weight:700;color:#2D2A26;margin-bottom:2px;}
.fs-poi-addr{font-size:10px;color:#8C8880;}
.fs-body{flex:1;overflow-y:auto;scrollbar-width:none;padding:13px 16px;display:flex;flex-direction:column;gap:13px;}
.fs-lbl{font-size:9px;font-weight:500;letter-spacing:.1em;text-transform:uppercase;color:#8C8880;margin-bottom:7px;}
.tag-row{display:flex;gap:6px;flex-wrap:wrap;}
.tag{font-size:12px;font-weight:500;padding:6px 11px;border-radius:13px;cursor:pointer;transition:all .12s;}
.tag-food{background:#FFDFC8;color:#8B3A1A;}.tag-coffee{background:#EDE0D0;color:#6B4423;}.tag-hotel{background:#D8E8FC;color:#1A3A7A;}.tag-sight{background:#D8F0E0;color:#1A5C2E;}.tag-bar{background:#EDD8F4;color:#5C1A6B;}
.tag.selected{box-shadow:0 0 0 2px #2D2A26;}
.status-toggle{display:flex;background:#EDE8E0;border-radius:11px;padding:3px;gap:2px;}
.st-btn{flex:1;text-align:center;font-size:11px;font-weight:500;padding:7px 0;border-radius:9px;cursor:pointer;color:#8C8880;transition:all .15s;}
.st-btn.active{background:#F5F0E8;color:#2D2A26;box-shadow:0 1px 3px rgba(0,0,0,.1);}
.note-field{background:#EDE8E0;border-radius:11px;padding:10px 12px;font-size:12px;color:#8C8880;min-height:56px;line-height:1.6;}
.save-btn{background:#2D2A26;color:#F5F0E8;border-radius:13px;padding:13px;text-align:center;font-size:14px;font-weight:500;cursor:pointer;flex-shrink:0;margin:0 16px 16px;transition:opacity .15s;}
.save-btn:hover{opacity:.88;}
.snackbar{position:absolute;bottom:96px;left:50%;transform:translateX(-50%) translateY(14px);background:#2D2A26;color:#F5F0E8;border-radius:13px;padding:10px 16px;font-size:12px;opacity:0;transition:all .3s;z-index:60;pointer-events:none;white-space:nowrap;}
.snackbar span{color:#B8906A;font-weight:500;}
</style>
</head>
<body>
<div class="hint" id="hintTxt">点击底部 <span>+</span> 开始收藏</div>
<div class="phone">
  <div class="map-layer" id="mapLayer">
    <svg class="map-svg" viewBox="0 0 300 640" xmlns="http://www.w3.org/2000/svg">
      <rect width="300" height="640" fill="#E9E5DC"/>
      <line x1="0" y1="160" x2="300" y2="160" stroke="#F2EDE4" stroke-width="12"/>
      <line x1="0" y1="320" x2="300" y2="320" stroke="#F2EDE4" stroke-width="10"/>
      <line x1="80" y1="0" x2="80" y2="640" stroke="#F2EDE4" stroke-width="12"/>
      <line x1="200" y1="0" x2="200" y2="640" stroke="#F2EDE4" stroke-width="10"/>
      <line x1="140" y1="0" x2="140" y2="640" stroke="#EDE8DF" stroke-width="4"/>
      <line x1="0" y1="240" x2="300" y2="240" stroke="#EDE8DF" stroke-width="4"/>
      <rect x="5" y="5" width="68" height="148" rx="5" fill="#DDD9CF"/>
      <rect x="88" y="5" width="104" height="148" rx="5" fill="#D8D4CA"/>
      <rect x="88" y="170" width="104" height="144" rx="5" fill="#DDD9CF"/>
      <rect x="208" y="5" width="88" height="148" rx="5" fill="#DDD9CF"/>
      <rect x="208" y="170" width="88" height="64" rx="5" fill="#DDD9CF"/>
      <rect x="5" y="478" width="188" height="90" rx="8" fill="#C4D8BC"/>
    </svg>
    <div class="sbar"><span class="sbt">9:41</span><span class="sbt">●●● ▌</span></div>
    <div class="nearby">视野内 · 4 个收藏</div>
    <div class="top-bar">
      <div class="top-row">
        <div class="city-pill"><div><div class="city-name">Tokyo</div><div class="city-sub">晴 · 12°C</div></div><div class="city-caret">▾</div></div>
        <div class="icon-btn">🔍</div>
        <div class="avatar-btn">🐕</div>
      </div>
      <div class="filter-row">
        <div class="fchip fc-all">全部</div>
        <div class="fchip fc-cat">🍜 美食</div>
        <div class="fchip fc-cat">☕ 咖啡</div>
        <div class="fchip fc-cat">📷 景点</div>
      </div>
    </div>
    <div class="pin" style="left:36%;top:37%;"><div class="pb pb-coffee">☕</div><div class="pt pt-coffee"></div></div>
    <div class="pin" style="left:67%;top:25%;"><div class="pb pb-food">🍜</div><div class="pt pt-food"></div></div>
    <div class="pin" style="left:74%;top:53%;"><div class="pb pb-sight">📷</div><div class="pt pt-sight"></div></div>
    <div class="cluster" style="left:82%;top:73%;">3</div>
    <div class="locdot" style="left:50%;top:75%;"></div>
    <div class="loc-btn">◎</div>
    <div class="fab" onclick="step1()">+</div>
  </div>
  <!-- POI SHEET -->
  <div class="poi-sheet" id="poiSheet">
    <div class="ps-handle"><div class="ps-bar"></div></div>
    <div class="ps-head">
      <div class="ps-title-row">
        <div class="ps-title">附近地点</div>
        <div style="display:flex;align-items:center;gap:8px;">
          <div class="step-ind"><div class="step-dot active"></div><div class="step-dot"></div></div>
          <div class="ps-close" onclick="closeAll()">×</div>
        </div>
      </div>
      <div class="ps-sub">选择你想收藏的地点 · 按距离排序</div>
    </div>
    <div class="ps-search"><span style="font-size:14px;color:#8C8880;">🔍</span><span style="font-size:12px;color:#8C8880;">搜索地点名称...</span></div>
    <div class="pdiv"></div>
    <div class="poi-list">
      <div class="poi-item" id="poi0" onclick="selectPOI(0)"><div class="poi-ico pic-coffee">☕</div><div style="flex:1;min-width:0;"><div class="poi-name">Blue Bottle Coffee 青山</div><div class="poi-meta">咖啡 · Minami-aoyama</div></div><div class="poi-dist">38m</div></div>
      <div class="poi-item" id="poi1" onclick="selectPOI(1)"><div class="poi-ico pic-food">🍜</div><div style="flex:1;min-width:0;"><div class="poi-name">一兰拉面 涉谷店</div><div class="poi-meta">美食 · Shibuya</div></div><div class="poi-dist">92m</div></div>
      <div class="poi-item" id="poi2" onclick="selectPOI(2)"><div class="poi-ico pic-coffee">☕</div><div style="flex:1;min-width:0;"><div class="poi-name">Streamer Coffee Company</div><div class="poi-meta">咖啡 · Harajuku</div></div><div class="poi-dist">145m</div></div>
      <div class="poi-item" id="poi3" onclick="selectPOI(3)"><div class="poi-ico pic-sight">📷</div><div style="flex:1;min-width:0;"><div class="poi-name">明治神宫</div><div class="poi-meta">景点 · Harajuku</div></div><div class="poi-dist">310m</div></div>
      <div class="poi-item" id="poi4" onclick="selectPOI(4)"><div class="poi-ico pic-bar">🍸</div><div style="flex:1;min-width:0;"><div class="poi-name">Bar Benfiddich</div><div class="poi-meta">酒吧 · Shinjuku</div></div><div class="poi-dist">480m</div></div>
      <div class="poi-item" id="poi5" onclick="selectPOI(5)"><div class="poi-ico pic-hotel">🏨</div><div style="flex:1;min-width:0;"><div class="poi-name">Trunk Hotel</div><div class="poi-meta">酒店 · Shibuya</div></div><div class="poi-dist">620m</div></div>
    </div>
    <div class="manual-row"><div class="manual-ico">📍</div><div style="font-size:12px;color:#8C8880;">找不到？<span class="manual-link">手动输入地点名称</span></div></div>
  </div>
  <!-- FORM SHEET -->
  <div class="form-sheet" id="formSheet">
    <div class="fs-handle"><div class="fs-bar"></div></div>
    <div class="fs-head">
      <div class="fs-step"><span class="fs-back" onclick="backToPOI()">← 重新选择</span><div class="step-ind"><div class="step-dot"></div><div class="step-dot active"></div></div></div>
      <div class="fs-poi-name" id="formPoiName">Blue Bottle Coffee 青山</div>
      <div class="fs-poi-addr" id="formPoiAddr">咖啡 · Minami-aoyama · 38m</div>
    </div>
    <div class="fs-body">
      <div><div class="fs-lbl">类型 *</div><div class="tag-row"><div class="tag tag-food" onclick="selTag(this)">🍜 美食</div><div class="tag tag-coffee selected" onclick="selTag(this)">☕ 咖啡</div><div class="tag tag-hotel" onclick="selTag(this)">🏨 酒店</div><div class="tag tag-sight" onclick="selTag(this)">📷 景点</div><div class="tag tag-bar" onclick="selTag(this)">🍸 酒吧</div></div></div>
      <div><div class="fs-lbl">打卡状态</div><div class="status-toggle"><div class="st-btn active" onclick="setSt('p',this)">待打卡</div><div class="st-btn" onclick="setSt('v',this)">已打卡 ✓</div></div></div>
      <div><div class="fs-lbl">备注（选填）</div><div class="note-field">加了个人记忆的锚点...</div></div>
    </div>
    <div class="save-btn" onclick="saveFlow()">保存收藏</div>
  </div>
  <div class="snackbar" id="sb">✓ 已收藏 · <span>查看</span></div>
</div>
<script>
const pois=[{name:'Blue Bottle Coffee 青山',addr:'咖啡 · Minami-aoyama · 38m'},{name:'一兰拉面 涉谷店',addr:'美食 · Shibuya · 92m'},{name:'Streamer Coffee Company',addr:'咖啡 · Harajuku · 145m'},{name:'明治神宫',addr:'景点 · Harajuku · 310m'},{name:'Bar Benfiddich',addr:'酒吧 · Shinjuku · 480m'},{name:'Trunk Hotel',addr:'酒店 · Shibuya · 620m'}];
function step1(){document.getElementById('mapLayer').classList.add('pushed');document.getElementById('poiSheet').classList.add('open');document.getElementById('hintTxt').innerHTML='Step 1 · <span>选择附近地点</span>';}
function selectPOI(i){document.querySelectorAll('.poi-item').forEach(e=>e.classList.remove('selected'));document.querySelectorAll('.poi-check').forEach(e=>e.remove());document.getElementById('poi'+i).classList.add('selected');const c=document.createElement('div');c.className='poi-check';c.textContent='✓';document.getElementById('poi'+i).appendChild(c);setTimeout(()=>{document.getElementById('poiSheet').classList.remove('open');document.getElementById('formPoiName').textContent=pois[i].name;document.getElementById('formPoiAddr').textContent=pois[i].addr;document.getElementById('formSheet').classList.add('open');document.getElementById('hintTxt').innerHTML='Step 2 · <span>填写标签和备注</span>';},220);}
function backToPOI(){document.getElementById('formSheet').classList.remove('open');document.getElementById('poiSheet').classList.add('open');document.getElementById('hintTxt').innerHTML='Step 1 · <span>选择附近地点</span>';}
function closeAll(){document.getElementById('poiSheet').classList.remove('open');document.getElementById('formSheet').classList.remove('open');document.getElementById('mapLayer').classList.remove('pushed');document.getElementById('hintTxt').innerHTML='点击底部 <span>+</span> 开始收藏';document.querySelectorAll('.poi-item').forEach(e=>e.classList.remove('selected'));document.querySelectorAll('.poi-check').forEach(e=>e.remove());}
function saveFlow(){document.getElementById('formSheet').classList.remove('open');document.getElementById('mapLayer').classList.remove('pushed');document.getElementById('hintTxt').innerHTML='✓ 收藏成功！再次点击 <span>+</span> 体验';const s=document.getElementById('sb');s.style.opacity='1';s.style.transform='translateX(-50%) translateY(0)';setTimeout(()=>{s.style.opacity='0';s.style.transform='translateX(-50%) translateY(14px)';},2800);}
function selTag(el){document.querySelectorAll('.tag').forEach(t=>t.classList.remove('selected'));el.classList.add('selected');}
function setSt(m,el){document.querySelectorAll('.st-btn').forEach(b=>b.classList.remove('active'));el.classList.add('active');}
</script>
</body>
</html>
```

---

## Pin 详情 Sheet + 导航选择器

点击地图 Pin 触发，地图上移保持可见。「我的备注」替代高德的「地点介绍」平台文案，底部三按钮替代「添加至/打卡/导航」。

点击「🧭 导航前往」弹出选择器（高德 / Google / Apple / 拷贝地址），TasteMap 不自建导航。

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>TasteMap · Pin 详情</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@700&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#E8E4DC;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;padding:2rem;gap:1rem;}
.hint{font-size:12px;color:#8C8880;}.hint span{background:#2D2A26;color:#F5F0E8;border-radius:8px;padding:3px 10px;font-size:11px;}
.phone{width:300px;height:640px;border-radius:40px;overflow:hidden;border:2px solid #C8C4BC;box-shadow:0 16px 48px rgba(0,0,0,.18);position:relative;background:#E9E5DC;flex-shrink:0;}
.map-layer{position:absolute;inset:0;z-index:1;transition:bottom .38s cubic-bezier(.32,0,.15,1);}
.map-layer.pushed{bottom:68%;}
.map-svg{width:100%;height:100%;}
.sbar{position:absolute;top:0;left:0;right:0;z-index:30;height:32px;display:flex;align-items:center;justify-content:space-between;padding:0 20px;background:linear-gradient(to bottom,rgba(245,240,232,.65),transparent);}
.sbt{font-size:11px;font-weight:500;color:#2D2A26;}
.top-bar{position:absolute;top:32px;left:0;right:0;z-index:25;padding:8px 14px 0;display:flex;flex-direction:column;gap:7px;}
.top-row{display:flex;align-items:center;gap:8px;}
.city-pill{display:flex;align-items:center;gap:6px;background:rgba(245,240,232,.92);border-radius:20px;padding:5px 13px;backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);flex:1;}
.city-name{font-family:'Noto Serif SC',serif;font-size:15px;font-weight:700;color:#2D2A26;line-height:1;}
.city-sub{font-size:9px;color:#8C8880;margin-top:1px;}
.city-caret{font-size:10px;color:#8C8880;margin-left:auto;}
.icon-btn{width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.avatar-btn{width:36px;height:36px;border-radius:50%;background:#C4A882;border:2px solid rgba(245,240,232,.9);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.filter-row{display:flex;gap:6px;overflow-x:auto;scrollbar-width:none;}
.filter-row::-webkit-scrollbar{display:none;}
.fchip{flex-shrink:0;font-size:11px;font-weight:500;padding:5px 11px;border-radius:18px;backdrop-filter:blur(8px);white-space:nowrap;}
.fc-all{background:rgba(45,42,38,.88);color:#F5F0E8;}
.fc-cat{background:rgba(245,240,232,.88);color:#4A4642;border:0.5px solid rgba(45,42,38,.1);}
.nearby{position:absolute;top:0;left:50%;transform:translateX(-50%);background:rgba(45,42,38,.82);color:#F5F0E8;font-size:10px;padding:3px 12px;border-radius:0 0 10px 10px;backdrop-filter:blur(4px);z-index:26;white-space:nowrap;}
.pin{position:absolute;z-index:15;transform:translate(-50%,-100%);display:flex;flex-direction:column;align-items:center;}
.pb{width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:18px;box-shadow:0 2px 8px rgba(0,0,0,.18);}
.pt{width:0;height:0;border-left:6px solid transparent;border-right:6px solid transparent;border-top:8px solid;margin-top:-1px;}
.pb-coffee{background:#EDE0D0;}.pt-coffee{border-top-color:#EDE0D0;}
.pb-food{background:#FFDFC8;}.pt-food{border-top-color:#FFDFC8;}
.pb-sight{background:#D8F0E0;}.pt-sight{border-top-color:#D8F0E0;}
.pb-sel{box-shadow:0 0 0 3px #2D2A26,0 2px 8px rgba(0,0,0,.22)!important;}
.cluster{position:absolute;z-index:14;transform:translate(-50%,-50%);width:32px;height:32px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:12px;font-weight:500;display:flex;align-items:center;justify-content:center;border:2.5px solid #F5F0E8;}
.locdot{position:absolute;z-index:13;width:14px;height:14px;border-radius:50%;background:#4878CC;border:2.5px solid #F5F0E8;box-shadow:0 0 0 5px rgba(72,120,204,.2);transform:translate(-50%,-50%);}
.fab{position:absolute;bottom:24px;left:50%;transform:translateX(-50%);width:52px;height:52px;border-radius:50%;background:#2D2A26;color:#F5F0E8;font-size:26px;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 16px rgba(0,0,0,.28);z-index:20;}
.loc-btn{position:absolute;right:14px;bottom:90px;z-index:20;width:36px;height:36px;border-radius:50%;background:rgba(245,240,232,.92);backdrop-filter:blur(8px);border:0.5px solid rgba(45,42,38,.1);display:flex;align-items:center;justify-content:center;font-size:15px;}
/* DETAIL SHEET */
.ds{position:absolute;bottom:0;left:0;right:0;z-index:40;background:#F5F0E8;border-radius:22px 22px 0 0;transform:translateY(0);display:flex;flex-direction:column;max-height:70%;box-shadow:0 -6px 28px rgba(0,0,0,.12);}
.ds-handle{display:flex;justify-content:center;padding:11px 0 5px;flex-shrink:0;}
.ds-bar{width:38px;height:4px;border-radius:2px;background:#D5D0CA;}
.ds-head{padding:0 16px 11px;flex-shrink:0;border-bottom:0.5px solid #E8E2DA;}
.ds-close{float:right;font-size:18px;color:#8C8880;cursor:pointer;}
.ds-name{font-family:'Noto Serif SC',serif;font-size:17px;font-weight:700;color:#2D2A26;line-height:1.35;margin-bottom:7px;padding-right:26px;}
.ds-meta{display:flex;align-items:center;gap:6px;flex-wrap:wrap;}
.dtag{font-size:11px;font-weight:500;padding:4px 9px;border-radius:11px;}
.dt-coffee{background:#EDE0D0;color:#6B4423;}.dt-s{background:#EDE8E0;color:#6B6560;}.dt-vis{background:#D8F0E0;color:#1A5C2E;}
.ds-body{flex:1;overflow-y:auto;scrollbar-width:none;padding:13px 16px 0;}
.ds-body::-webkit-scrollbar{display:none;}
.photo-strip{display:flex;gap:7px;margin-bottom:13px;}
.photo-thumb{height:82px;border-radius:11px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:28px;}
.sec-lbl{font-size:9px;font-weight:500;letter-spacing:.1em;text-transform:uppercase;color:#8C8880;margin-bottom:5px;}
.note-text{font-size:12px;color:#4A4642;line-height:1.65;margin-bottom:13px;}
.sdiv{height:0.5px;background:#E8E2DA;margin:0 0 10px;}
.info-row{display:flex;align-items:center;gap:11px;padding:10px 0;border-bottom:0.5px solid #ECEAE3;cursor:pointer;}
.info-row:last-child{border-bottom:none;}
.info-ico{font-size:15px;width:20px;text-align:center;flex-shrink:0;color:#8C8880;}
.info-title{font-size:12px;color:#2D2A26;font-weight:500;}
.info-sub{font-size:10px;color:#8C8880;margin-top:2px;}
.info-arrow{font-size:14px;color:#C5C0B8;margin-left:auto;}
.ds-foot{flex-shrink:0;padding:9px 16px 16px;border-top:0.5px solid #E8E2DA;display:flex;gap:7px;background:#F5F0E8;}
.dfbtn{flex:1;border-radius:12px;padding:10px 0;text-align:center;font-size:12px;font-weight:500;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:4px;transition:opacity .15s;}
.dfbtn:hover{opacity:.85;}
.dfb-edit{background:#EDE8E0;color:#4A4642;flex:.8;}
.dfb-nav{background:#2D2A26;color:#F5F0E8;flex:1.4;}
.dfb-del{background:#FDDCD8;color:#C04040;flex:.7;}
/* NAV PICKER */
.nav-overlay{position:absolute;inset:0;z-index:60;background:rgba(45,42,38,0);transition:background .28s;pointer-events:none;border-radius:40px;overflow:hidden;}
.nav-overlay.open{background:rgba(45,42,38,.42);pointer-events:all;}
.nav-picker{position:absolute;bottom:0;left:0;right:0;transform:translateY(100%);transition:transform .32s cubic-bezier(.32,0,.15,1);display:flex;flex-direction:column;z-index:61;gap:8px;padding:0 10px 14px;}
.nav-picker.open{transform:translateY(0);}
.np-card{background:#F5F0E8;border-radius:18px;overflow:hidden;}
.np-header{padding:13px 16px 11px;text-align:center;border-bottom:0.5px solid #E8E2DA;}
.np-header-lbl{font-size:11px;color:#8C8880;}
.np-header-addr{font-size:11px;color:#2D2A26;font-weight:500;margin-top:3px;}
.np-item{display:flex;align-items:center;gap:13px;padding:14px 16px;border-bottom:0.5px solid #ECEAE3;cursor:pointer;transition:background .1s;}
.np-item:last-child{border-bottom:none;}
.np-item:hover{background:#EDE8E0;}
.np-ico{width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;}
.np-name{font-size:14px;font-weight:500;color:#2D2A26;}
.np-sub{font-size:10px;color:#8C8880;margin-top:2px;}
.np-arrow{margin-left:auto;font-size:14px;color:#C5C0B8;}
.np-copy{display:flex;align-items:center;gap:13px;padding:14px 16px;cursor:pointer;transition:background .1s;}
.np-copy:hover{background:#EDE8E0;}
.np-cancel{background:#F5F0E8;border-radius:16px;padding:15px;text-align:center;font-size:15px;font-weight:500;color:#2D2A26;cursor:pointer;transition:background .1s;}
.np-cancel:hover{background:#EDE8E0;}
.toast{position:absolute;bottom:90px;left:50%;transform:translateX(-50%) translateY(12px);background:#2D2A26;color:#F5F0E8;border-radius:12px;padding:9px 16px;font-size:12px;opacity:0;transition:all .28s;z-index:70;pointer-events:none;white-space:nowrap;}
</style>
</head>
<body>
<div class="hint">点击 <span>🧭 导航前往</span> 体验导航选择器</div>
<div class="phone">
  <div class="map-layer" id="ml" style="bottom:32%;">
    <svg class="map-svg" viewBox="0 0 300 640" xmlns="http://www.w3.org/2000/svg">
      <rect width="300" height="640" fill="#E9E5DC"/>
      <line x1="0" y1="160" x2="300" y2="160" stroke="#F2EDE4" stroke-width="12"/>
      <line x1="0" y1="320" x2="300" y2="320" stroke="#F2EDE4" stroke-width="10"/>
      <line x1="80" y1="0" x2="80" y2="640" stroke="#F2EDE4" stroke-width="12"/>
      <line x1="200" y1="0" x2="200" y2="640" stroke="#F2EDE4" stroke-width="10"/>
      <rect x="5" y="5" width="68" height="148" rx="5" fill="#DDD9CF"/>
      <rect x="88" y="5" width="104" height="148" rx="5" fill="#D8D4CA"/>
      <rect x="208" y="5" width="88" height="148" rx="5" fill="#DDD9CF"/>
      <rect x="88" y="170" width="104" height="144" rx="5" fill="#DDD9CF"/>
      <rect x="5" y="478" width="188" height="90" rx="8" fill="#C4D8BC"/>
    </svg>
    <div class="sbar"><span class="sbt">9:41</span><span class="sbt">●●● ▌</span></div>
    <div class="nearby">视野内 · 4 个收藏</div>
    <div class="top-bar">
      <div class="top-row">
        <div class="city-pill"><div><div class="city-name">Tokyo</div><div class="city-sub">晴 · 12°C</div></div><div class="city-caret">▾</div></div>
        <div class="icon-btn">🔍</div>
        <div class="avatar-btn">🐕</div>
      </div>
      <div class="filter-row">
        <div class="fchip fc-all">全部</div>
        <div class="fchip fc-cat">🍜 美食</div>
        <div class="fchip fc-cat">☕ 咖啡</div>
        <div class="fchip fc-cat">📷 景点</div>
      </div>
    </div>
    <div class="pin" style="left:37%;top:36%;"><div class="pb pb-coffee pb-sel">☕</div><div class="pt pt-coffee"></div></div>
    <div class="pin" style="left:67%;top:25%;"><div class="pb pb-food">🍜</div><div class="pt pt-food"></div></div>
    <div class="pin" style="left:74%;top:50%;"><div class="pb pb-sight">📷</div><div class="pt pt-sight"></div></div>
    <div class="cluster" style="left:82%;top:72%;">3</div>
    <div class="locdot" style="left:50%;top:74%;"></div>
    <div class="loc-btn">◎</div>
    <div class="fab">+</div>
  </div>
  <!-- DETAIL SHEET -->
  <div class="ds">
    <div class="ds-handle"><div class="ds-bar"></div></div>
    <div class="ds-head">
      <span class="ds-close">×</span>
      <div class="ds-name">Fuglen Tokyo</div>
      <div class="ds-meta"><span class="dtag dt-coffee">☕ 咖啡</span><span class="dtag dt-s">值得二刷</span><span class="dtag dt-s">氛围好</span><span class="dtag dt-vis">✓ 已打卡</span></div>
    </div>
    <div class="ds-body">
      <div class="photo-strip">
        <div class="photo-thumb" style="width:120px;background:linear-gradient(135deg,#EDE0D0,#C4A882);">☕</div>
        <div class="photo-thumb" style="width:76px;background:linear-gradient(135deg,#DDD4C4,#B09878);">🥐</div>
      </div>
      <div class="sec-lbl">我的备注</div>
      <div class="note-text">窗边的位置可以俯瞰整条街道，flat white 做得很出色，肉桂卷也值得一试。和朋友呆了两个多小时也不觉得被打扰。</div>
      <div class="sdiv"></div>
      <div class="info-row" style="cursor:default;"><div class="info-ico">📅</div><div><div class="info-title">收藏时间</div><div class="info-sub">2025年11月03日</div></div></div>
      <div class="info-row" onclick="showToast('✓ 地址已复制')"><div class="info-ico">📍</div><div><div class="info-title">Tomigaya 1-16-11, Shibuya</div><div class="info-sub">Tokyo, 日本 · 点击复制地址</div></div><div class="info-arrow">›</div></div>
      <div style="height:10px;"></div>
    </div>
    <div class="ds-foot">
      <div class="dfbtn dfb-edit">✏️ 编辑</div>
      <div class="dfbtn dfb-nav" onclick="openNav()">🧭 导航前往</div>
      <div class="dfbtn dfb-del">🗑</div>
    </div>
  </div>
  <!-- NAV PICKER -->
  <div class="nav-overlay" id="no" onclick="closeNav()">
    <div class="nav-picker" id="np" onclick="event.stopPropagation()">
      <div class="np-card">
        <div class="np-header"><div class="np-header-lbl">前往</div><div class="np-header-addr">Fuglen Tokyo · Tomigaya 1-16-11</div></div>
        <div class="np-item" onclick="launchNav('高德地图')"><div class="np-ico" style="background:#FDDCD8;">🗺</div><div><div class="np-name">高德地图</div><div class="np-sub">跳转到高德导航</div></div><div class="np-arrow">›</div></div>
        <div class="np-item" onclick="launchNav('Google Maps')"><div class="np-ico" style="background:#D8E8FC;">🌐</div><div><div class="np-name">Google Maps</div><div class="np-sub">跳转到 Google 导航</div></div><div class="np-arrow">›</div></div>
        <div class="np-item" onclick="launchNav('Apple 地图')" style="border-bottom:none;"><div class="np-ico" style="background:#EAF6ED;">🍎</div><div><div class="np-name">Apple 地图</div><div class="np-sub">跳转到 Apple 导航</div></div><div class="np-arrow">›</div></div>
      </div>
      <div class="np-card"><div class="np-copy" onclick="copyNav()"><div class="np-ico" style="background:#EDE8E0;width:34px;height:34px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0;">📋</div><div class="np-name">拷贝地址</div></div></div>
      <div class="np-cancel" onclick="closeNav()">取消</div>
    </div>
  </div>
  <div class="toast" id="toast"></div>
</div>
<script>
function openNav(){document.getElementById('no').classList.add('open');document.getElementById('np').classList.add('open');}
function closeNav(){document.getElementById('no').classList.remove('open');document.getElementById('np').classList.remove('open');}
function launchNav(a){closeNav();showToast('✓ 正在跳转 '+a+'...');}
function copyNav(){closeNav();setTimeout(()=>showToast('✓ 地址已复制'),340);}
function showToast(m){const t=document.getElementById('toast');t.textContent=m;t.style.opacity='1';t.style.transform='translateX(-50%) translateY(0)';clearTimeout(t._t);t._t=setTimeout(()=>{t.style.opacity='0';t.style.transform='translateX(-50%) translateY(12px)';},2400);}
</script>
</body>
</html>
```

---

## Profile + 设置

头像点击后的 Profile 页（界面一）和右上角三横线触发的设置页（界面二）。参照圆周旅迹的结构，内容完全替换为个人收藏数据。

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>TasteMap · Profile</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@400;500;700&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'DM Sans',sans-serif;background:#E8E4DC;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;padding:2rem;gap:1rem;}
.hint{font-size:12px;color:#8C8880;}.hint span{background:#2D2A26;color:#F5F0E8;border-radius:8px;padding:3px 10px;font-size:11px;}
.phone{width:300px;height:640px;border-radius:40px;overflow:hidden;border:2px solid #C8C4BC;box-shadow:0 16px 48px rgba(0,0,0,.18);position:relative;flex-shrink:0;background:#F0EDE8;}
.sbar{height:30px;display:flex;align-items:center;justify-content:space-between;padding:0 18px;flex-shrink:0;}
.sbt{font-size:11px;font-weight:500;color:#2D2A26;}
.s1{position:absolute;inset:0;overflow-y:auto;scrollbar-width:none;display:flex;flex-direction:column;background:#F0EDE8;}
.s1::-webkit-scrollbar{display:none;}
.s1-nav{display:flex;align-items:center;justify-content:space-between;padding:4px 16px 0;}
.nav-back{font-size:18px;color:#2D2A26;cursor:pointer;width:30px;height:30px;display:flex;align-items:center;justify-content:center;}
.nav-menu{cursor:pointer;width:30px;height:30px;display:flex;flex-direction:column;justify-content:center;gap:4px;}
.menu-bar{height:2px;background:#2D2A26;border-radius:1px;width:100%;}
.hero-card{margin:10px 14px 0;border-radius:22px;overflow:hidden;background:linear-gradient(160deg,#E8F0F8 0%,#D4E4F4 100%);flex-shrink:0;position:relative;}
.stamp{position:absolute;top:14px;right:16px;width:66px;height:66px;border-radius:50%;border:2px dashed #2D2A26;opacity:.18;display:flex;flex-direction:column;align-items:center;justify-content:center;font-size:8px;font-weight:500;color:#2D2A26;text-align:center;line-height:1.4;}
.stamp-num{font-family:'Noto Serif SC',serif;font-size:22px;font-weight:700;line-height:1;}
.hero-top{padding:16px 16px 0;display:flex;gap:13px;align-items:flex-start;}
.avatar{width:64px;height:64px;border-radius:15px;flex-shrink:0;background:linear-gradient(135deg,#C4A882,#8B6A44);display:flex;align-items:center;justify-content:center;font-size:30px;border:2px solid rgba(255,255,255,.6);}
.profile-nick{font-family:'Noto Serif SC',serif;font-size:16px;font-weight:700;color:#2D2A26;margin-bottom:5px;display:flex;align-items:center;gap:5px;}
.profile-sub{font-size:10px;color:#6B7A8A;margin-bottom:9px;}
.profile-stats{display:flex;gap:16px;}
.pstat-num{font-family:'Noto Serif SC',serif;font-size:18px;font-weight:700;color:#2D2A26;line-height:1;}
.pstat-lbl{font-size:9px;color:#6B7A8A;margin-top:2px;}
.hero-map{margin:13px 0 0;height:108px;position:relative;overflow:hidden;}
.hero-map-svg{width:100%;height:100%;}
.checkin-dot{position:absolute;transform:translate(-50%,-50%);width:24px;height:24px;border-radius:50%;background:#4878CC;display:flex;align-items:center;justify-content:center;border:2.5px solid #fff;box-shadow:0 1px 6px rgba(72,120,204,.4);font-size:11px;color:#fff;z-index:5;}
.hero-cta{position:absolute;bottom:11px;right:12px;background:#2D2A26;color:#F5F0E8;border-radius:17px;padding:7px 13px;font-size:11px;font-weight:500;cursor:pointer;}
.section{margin:11px 14px 0;}
.sec-card{background:#fff;border-radius:18px;padding:15px;box-shadow:0 1px 6px rgba(0,0,0,.05);}
.sec-title{font-family:'Noto Serif SC',serif;font-size:14px;font-weight:700;color:#2D2A26;margin-bottom:11px;display:flex;align-items:center;justify-content:space-between;}
.sec-more{font-size:11px;color:#B8906A;cursor:pointer;}
.coll-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:7px;}
.coll-thumb{aspect-ratio:1;border-radius:11px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;cursor:pointer;position:relative;overflow:hidden;}
.coll-thumb-ico{font-size:22px;}
.coll-thumb-name{font-size:8px;color:#4A4642;text-align:center;line-height:1.3;padding:0 3px;}
.coll-thumb-badge{position:absolute;top:5px;right:5px;width:9px;height:9px;border-radius:50%;border:1.5px solid #fff;}
.tb-v{background:#3A9C58;}.tb-p{background:#B8906A;}
.ct-food{background:#FFF0E8;}.ct-coffee{background:#F5EFE6;}.ct-sight{background:#EAF6ED;}.ct-bar{background:#F5EAF6;}.ct-hotel{background:#EAF0FB;}.ct-more{background:#F0EDE8;border:1.5px dashed #C5C0B8;}
.city-row{display:flex;align-items:center;gap:11px;padding:9px 0;border-bottom:0.5px solid #F0EDE8;}
.city-row:last-child{border-bottom:none;}
.city-flag{width:30px;height:30px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;}
.city-name-t{font-size:13px;font-weight:500;color:#2D2A26;}
.city-sub-t{font-size:10px;color:#8C8880;}
.city-count{font-size:11px;font-weight:500;color:#B8906A;flex-shrink:0;margin-left:auto;}
/* SCREEN 2 */
.s2{position:absolute;inset:0;background:#fff;transform:translateX(100%);transition:transform .3s cubic-bezier(.32,0,.15,1);z-index:50;display:flex;flex-direction:column;overflow-y:auto;scrollbar-width:none;}
.s2::-webkit-scrollbar{display:none;}
.s2.open{transform:translateX(0);}
.s2-nav{display:flex;align-items:center;gap:11px;padding:34px 16px 13px;flex-shrink:0;}
.s2-back{font-size:18px;cursor:pointer;color:#2D2A26;width:30px;height:30px;display:flex;align-items:center;justify-content:center;}
.s2-title{font-family:'Noto Serif SC',serif;font-size:16px;font-weight:700;color:#2D2A26;}
.s2-lbl{font-size:10px;font-weight:500;letter-spacing:.1em;text-transform:uppercase;color:#8C8880;padding:11px 18px 5px;}
.s2-item{display:flex;align-items:center;gap:13px;padding:14px 18px;cursor:pointer;border-bottom:0.5px solid #F5F0E8;transition:background .1s;}
.s2-item:hover{background:#FAFAF8;}
.s2-ico{width:36px;height:36px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;}
.s2-title-t{font-size:14px;font-weight:500;color:#2D2A26;margin-bottom:2px;}
.s2-sub{font-size:11px;color:#8C8880;}
.s2-arrow{margin-left:auto;font-size:15px;color:#C5C0B8;}
.s2-badge{font-size:10px;padding:2px 7px;border-radius:7px;background:#D8F0E0;color:#1A5C2E;font-weight:500;}
.s2-danger .s2-title-t{color:#C04040;}
.s2-foot{padding:22px 18px;margin-top:auto;}
.s2-ver{font-size:11px;color:#C5C0B8;text-align:center;}
</style>
</head>
<body>
<div class="hint">点击右上角 <span>三横线</span> 进入设置</div>
<div class="phone">
  <div class="s1">
    <div class="sbar"><span class="sbt">9:41</span><span class="sbt">●●● ▌</span></div>
    <div class="s1-nav">
      <div class="nav-back">←</div>
      <div class="nav-menu" onclick="openS2()"><div class="menu-bar"></div><div class="menu-bar" style="width:70%;"></div><div class="menu-bar"></div></div>
    </div>
    <div class="hero-card">
      <div class="stamp"><div style="font-size:8px;">TASTE</div><div class="stamp-num">12</div><div style="font-size:8px;">收藏</div></div>
      <div class="hero-top">
        <div class="avatar">🐕</div>
        <div>
          <div class="profile-nick">旅行者 <span style="font-size:14px;">🥝</span></div>
          <div class="profile-sub">个人品味地图 · 自 2025.09</div>
          <div class="profile-stats">
            <div><div class="pstat-num">12</div><div class="pstat-lbl">收藏</div></div>
            <div><div class="pstat-num">3</div><div class="pstat-lbl">城市</div></div>
            <div><div class="pstat-num">2</div><div class="pstat-lbl">国家</div></div>
          </div>
        </div>
      </div>
      <div class="hero-map">
        <svg class="hero-map-svg" viewBox="0 0 300 108" xmlns="http://www.w3.org/2000/svg">
          <rect width="300" height="108" fill="#DDE8EE"/>
          <line x1="0" y1="44" x2="300" y2="44" stroke="#EEF3F7" stroke-width="10"/>
          <line x1="72" y1="0" x2="72" y2="108" stroke="#EEF3F7" stroke-width="10"/>
          <line x1="178" y1="0" x2="178" y2="108" stroke="#EEF3F7" stroke-width="8"/>
          <rect x="5" y="5" width="60" height="35" rx="4" fill="#CDD8E0"/>
          <rect x="80" y="5" width="90" height="35" rx="4" fill="#C8D4DC"/>
          <rect x="186" y="5" width="110" height="35" rx="4" fill="#CDD8E0"/>
          <rect x="5" y="82" width="130" height="22" rx="4" fill="#B8D0BC" opacity=".7"/>
        </svg>
        <div class="checkin-dot" style="left:32%;top:48%;">✓</div>
        <div class="checkin-dot" style="left:70%;top:30%;">✓</div>
        <div class="hero-cta">去地图看看 →</div>
      </div>
    </div>
    <div class="section">
      <div class="sec-card">
        <div class="sec-title">我的收藏 <span style="color:#8C8880;font-size:12px;font-weight:400;">· 12</span><span class="sec-more">查看全部 ›</span></div>
        <div class="coll-grid">
          <div class="coll-thumb ct-coffee"><div class="coll-thumb-badge tb-v"></div><div class="coll-thumb-ico">☕</div><div class="coll-thumb-name">Fuglen Tokyo</div></div>
          <div class="coll-thumb ct-food"><div class="coll-thumb-badge tb-v"></div><div class="coll-thumb-ico">🍜</div><div class="coll-thumb-name">蔦屋旁拉面</div></div>
          <div class="coll-thumb ct-sight"><div class="coll-thumb-badge tb-p"></div><div class="coll-thumb-ico">📷</div><div class="coll-thumb-name">浅草寺</div></div>
          <div class="coll-thumb ct-bar"><div class="coll-thumb-badge tb-p"></div><div class="coll-thumb-ico">🍸</div><div class="coll-thumb-name">Sober Co.</div></div>
          <div class="coll-thumb ct-hotel"><div class="coll-thumb-badge tb-v"></div><div class="coll-thumb-ico">🏨</div><div class="coll-thumb-name">Trunk Hotel</div></div>
          <div class="coll-thumb ct-more"><div style="font-size:18px;color:#8C8880;">+7</div><div class="coll-thumb-name" style="color:#8C8880;">更多</div></div>
        </div>
      </div>
    </div>
    <div class="section">
      <div class="sec-card">
        <div class="sec-title">城市足迹</div>
        <div class="city-row"><div class="city-flag" style="background:#FFF0E8;">🗾</div><div style="flex:1;"><div class="city-name-t">Tokyo</div><div class="city-sub-t">日本 · 2025.11</div></div><div class="city-count">6 个</div></div>
        <div class="city-row"><div class="city-flag" style="background:#F5EFE6;">🇨🇳</div><div style="flex:1;"><div class="city-name-t">上海</div><div class="city-sub-t">中国 · 2025.09</div></div><div class="city-count">4 个</div></div>
        <div class="city-row"><div class="city-flag" style="background:#EAF6ED;">🇨🇳</div><div style="flex:1;"><div class="city-name-t">重庆</div><div class="city-sub-t">中国 · 2025.08</div></div><div class="city-count">2 个</div></div>
      </div>
    </div>
    <div style="height:26px;flex-shrink:0;"></div>
  </div>
  <!-- SCREEN 2 -->
  <div class="s2" id="s2">
    <div class="sbar"><span class="sbt">9:41</span><span class="sbt">●●● ▌</span></div>
    <div class="s2-nav"><div class="s2-back" onclick="closeS2()">←</div><div class="s2-title">更多</div></div>
    <div class="s2-lbl">数据与同步</div>
    <div class="s2-item"><div class="s2-ico" style="background:#EAF0FB;">☁️</div><div style="flex:1;"><div class="s2-title-t">坚果云同步</div><div class="s2-sub">上次同步 · 14:22</div></div><div class="s2-badge">已连接</div><div class="s2-arrow">›</div></div>
    <div class="s2-item"><div class="s2-ico" style="background:#EAF6ED;">📤</div><div style="flex:1;"><div class="s2-title-t">导出数据</div><div class="s2-sub">导出为 JSON / CSV</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-lbl">应用</div>
    <div class="s2-item"><div class="s2-ico" style="background:#FFF0E8;">🗺</div><div style="flex:1;"><div class="s2-title-t">地图设置</div><div class="s2-sub">默认地图类型 · 缓存</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-item"><div class="s2-ico" style="background:#F5EFE6;">🔔</div><div style="flex:1;"><div class="s2-title-t">通知</div><div class="s2-sub">附近收藏提醒</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-lbl">关于</div>
    <div class="s2-item"><div class="s2-ico" style="background:#F0EDE8;">ℹ️</div><div style="flex:1;"><div class="s2-title-t">版本信息</div><div class="s2-sub">TasteMap v1.0.0</div></div></div>
    <div class="s2-item"><div class="s2-ico" style="background:#F0EDE8;">💬</div><div style="flex:1;"><div class="s2-title-t">和开发者聊聊</div><div class="s2-sub">反馈问题 · 提建议</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-item"><div class="s2-ico" style="background:#F0EDE8;">📖</div><div style="flex:1;"><div class="s2-title-t">使用说明</div><div class="s2-sub">长按 + · 同步配置</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-lbl">数据管理</div>
    <div class="s2-item s2-danger"><div class="s2-ico" style="background:#FDDCD8;">🗑</div><div style="flex:1;"><div class="s2-title-t">清除所有收藏</div><div class="s2-sub">操作不可逆，请谨慎</div></div><div class="s2-arrow">›</div></div>
    <div class="s2-foot"><div class="s2-ver">TasteMap · v1.0.0 · 把你喜欢的地方，钉在地图上</div></div>
  </div>
</div>
<script>
function openS2(){document.getElementById('s2').classList.add('open');}
function closeS2(){document.getElementById('s2').classList.remove('open');}
</script>
</body>
</html>
```

---

## 关键设计决策

| # | 决策 | 原因 |
|---|------|------|
| DDR-01 | 取消底部 Tab Bar，导航收进头像 Drawer | 地图是唯一主角，低频功能不值得常驻导航栏 |
| DDR-02 | POI 列表 6 条而非 PRD 的 10 条 | 目标地点 90% 在前 2–3 条，10 条需滚动破坏 3 秒目标 |
| DDR-03 | 两步收藏共享一个 Sheet 容器 | 避免两层叠加，地图始终保持在视野内 |
| DDR-04 | Pin 无常驻文字标签 | 私人地图用户有记忆，Emoji 即锚点；文字标签是公共地图的需求 |
| DDR-05 | 导航跳外部地图，不自建 | 自建成本高且无竞争优势；提供高德/Google/Apple 三选项覆盖国际用户 |
| DDR-06 | 「我的备注」替代「地点介绍」 | 产品最直观差异：数据 100% 来自用户，而非平台爬取 |
| DDR-07 | 删除弹窗文案点名地点名 | 具名文案让用户感受到失去的代价，减少误删 |
| DDR-08 | 统计空状态用灰色预览占位 | 完全空白让用户以为是 Bug；预览设置正确期望 |

---

## 技术选型

| 模块 | 方案 | 费用 |
|-----|------|------|
| 框架 | Flutter + Dart | 免费 |
| 地图 | flutter_map + OpenStreetMap | 免费 |
| POI | Foursquare Places API | 免费 12万/月 |
| 逆地理 | Nominatim (OSM) | 免费 |
| 存储 | sqflite (SQLite) | 免费 |
| 同步 | 坚果云 WebDAV | 免费 |
| 图片压缩 | flutter_image_compress | 免费 |
| 导航跳转 | url_launcher | 免费 |
| iOS 打包 | Codemagic 免费层 | 500 分钟/月 |
