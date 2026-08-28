import 'package:flutter_test/flutter_test.dart';

import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';

void main() {
  test('PrimaryTag 枚举映射', () {
    expect(PrimaryTag.fromName('food'), PrimaryTag.food);
    expect(PrimaryTag.fromName('coffee'), PrimaryTag.coffee);
    expect(PrimaryTag.fromName('未知值'), PrimaryTag.food); // 兜底
    expect(PrimaryTag.food.emoji, '🍜');
    expect(PrimaryTag.food.label, '美食');
    expect(PrimaryTag.bar.emoji, '🍸');
    expect(PrimaryTag.bar.label, '酒吧');
  });

  test('Place 序列化往返', () {
    const place = Place(
      id: 'p1',
      name: '测试咖啡馆',
      latitude: 35.6580,
      longitude: 139.7016,
      city: 'Tokyo',
      country: '日本',
      createdAt: '2025-11-03T00:00:00',
    );
    final restored = Place.fromMap(place.toMap());
    expect(restored.id, 'p1');
    expect(restored.name, '测试咖啡馆');
    expect(restored.latitude, 35.6580);
    expect(restored.city, 'Tokyo');
    expect(restored.type, 'custom');
  });

  test('Collection 序列化往返（含 JSON 数组）', () {
    const collection = Collection(
      id: 'c1',
      placeId: 'p1',
      primaryTag: PrimaryTag.coffee,
      secondaryTags: ['值得二刷', '氛围好'],
      note: '好喝',
      images: ['a.jpg', 'b.jpg'],
      visitedStatus: 'visited',
      createdAt: '2025-11-03T00:00:00',
      updatedAt: '2025-11-03T00:00:00',
    );
    final restored = Collection.fromMap(collection.toMap());
    expect(restored.primaryTag, PrimaryTag.coffee);
    expect(restored.secondaryTags, ['值得二刷', '氛围好']);
    expect(restored.images, ['a.jpg', 'b.jpg']);
    expect(restored.note, '好喝');
    expect(restored.visited, isTrue);
  });

  test('CollectionView 从 JOIN 行解析', () {
    final row = <String, Object?>{
      'id': 'c1',
      'place_id': 'p1',
      'primary_tag': 'sight',
      'secondary_tags': '[]',
      'note': '',
      'images': '[]',
      'visited_status': 'pending',
      'created_at': '2025-11-03T00:00:00',
      'updated_at': '2025-11-03T00:00:00',
      'name': '明治神宫',
      'latitude': 35.6764,
      'longitude': 139.6993,
      'city': 'Tokyo',
      'country': '日本',
      'type': 'custom',
      'source': null,
      'foursquare_id': null,
    };
    final view = CollectionView.fromRow(row);
    expect(view.name, '明治神宫');
    expect(view.tag, PrimaryTag.sight);
    expect(view.visited, isFalse);
    expect(view.city, 'Tokyo');
    expect(view.latitude, 35.6764);
  });
}
