import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/data/collection_repository.dart';
import 'package:tastemap/models/collection.dart';
import 'package:tastemap/models/collection_view.dart';
import 'package:tastemap/models/place.dart';
import 'package:tastemap/models/primary_tag.dart';
import 'package:tastemap/state/collection_provider.dart';

class DeletionRepository extends CollectionRepository {
  final custom = PrimaryTag.custom('书店');
  final settings = <String, String>{};
  late Collection collection = Collection(
    id: 'c',
    placeId: 'p',
    primaryTag: custom,
    secondaryTags: ['安静', '氛围好'],
    note: '保留备注',
    images: ['photo.jpg'],
    createdAt: '',
    updatedAt: '',
  );
  final place = const Place(
    id: 'p',
    name: '测试地点',
    latitude: 31,
    longitude: 121,
    createdAt: '',
  );
  @override
  Future<List<CollectionView>> getCollectionViews() async => [
    CollectionView(collection: collection, place: place),
  ];
  @override
  Future<String?> getSetting(String key) async => settings[key];
  @override
  Future<bool> setSetting(String key, String value) async {
    settings[key] = value;
    return true;
  }

  @override
  Future<bool> removeCustomType(PrimaryTag tag, List<String> remaining) async {
    collection = collection.copyWith(primaryTag: PrimaryTag.other);
    settings['custom_types'] = jsonEncode(remaining);
    return true;
  }

  @override
  Future<bool> removeCustomLabel(String label, List<String> remaining) async {
    collection = collection.copyWith(
      secondaryTags: collection.secondaryTags.where((v) => v != label).toList(),
    );
    settings['custom_labels'] = jsonEncode(remaining);
    return true;
  }
}

void main() {
  test('删除已使用的类型与标签后不复活，收藏地点、备注、图片保留', () async {
    final repo = DeletionRepository();
    repo.settings['custom_types'] = jsonEncode([repo.custom.name]);
    repo.settings['custom_labels'] = jsonEncode(['安静']);
    final provider = CollectionProvider(repository: repo);
    await provider.load();
    provider.setTag(repo.custom);
    expect(await provider.removeType(repo.custom), isTrue);
    expect(provider.selectedTag, isNull);
    expect(provider.tagOptions, isNot(contains(repo.custom)));
    expect(provider.all.single.tag, PrimaryTag.other);
    expect(await provider.removeLabel('安静'), isTrue);
    expect(provider.labelOptions, isNot(contains('安静')));
    expect(provider.all.single.secondaryTags, ['氛围好']);
    expect(provider.all.single.note, '保留备注');
    expect(provider.all.single.images, ['photo.jpg']);
    expect(provider.all.single.place.name, '测试地点');
    final reloaded = CollectionProvider(repository: repo);
    await reloaded.load();
    expect(reloaded.tagOptions, isNot(contains(repo.custom)));
    expect(reloaded.labelOptions, isNot(contains('安静')));
    expect(await provider.removeType(PrimaryTag.food), isFalse);
    expect(await provider.removeLabel('氛围好'), isFalse);
    provider.dispose();
    reloaded.dispose();
  });
}
