import '../models/primary_tag.dart';

/// 附近地点示例数据（P0 降级方案）。
/// 暂未接入 Foursquare Places API，先用东京涩谷周边 6 条示例数据跑通收藏闭环；
/// 待配置 API key 后替换为真实附近 POI 搜索。
class MockPoi {
  final String name;
  final PrimaryTag tag;
  final String addr;
  final String distance;
  final double latitude;
  final double longitude;

  const MockPoi({
    required this.name,
    required this.tag,
    required this.addr,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });
}

const List<MockPoi> mockPois = [
  MockPoi(
    name: 'Blue Bottle Coffee 青山',
    tag: PrimaryTag.coffee,
    addr: '咖啡 · Minami-aoyama',
    distance: '38m',
    latitude: 35.6663,
    longitude: 139.7126,
  ),
  MockPoi(
    name: '一兰拉面 涉谷店',
    tag: PrimaryTag.food,
    addr: '美食 · Shibuya',
    distance: '92m',
    latitude: 35.6595,
    longitude: 139.7005,
  ),
  MockPoi(
    name: 'Streamer Coffee Company',
    tag: PrimaryTag.coffee,
    addr: '咖啡 · Harajuku',
    distance: '145m',
    latitude: 35.6702,
    longitude: 139.7027,
  ),
  MockPoi(
    name: '明治神宫',
    tag: PrimaryTag.sight,
    addr: '景点 · Harajuku',
    distance: '310m',
    latitude: 35.6764,
    longitude: 139.6993,
  ),
  MockPoi(
    name: 'Bar Benfiddich',
    tag: PrimaryTag.bar,
    addr: '酒吧 · Shinjuku',
    distance: '480m',
    latitude: 35.6938,
    longitude: 139.7034,
  ),
  MockPoi(
    name: 'Trunk Hotel',
    tag: PrimaryTag.hotel,
    addr: '酒店 · Shibuya',
    distance: '620m',
    latitude: 35.6557,
    longitude: 139.6999,
  ),
];
