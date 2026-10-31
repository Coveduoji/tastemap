import 'package:flutter_test/flutter_test.dart';
import 'package:tastemap/utils/format.dart';

void main() {
  test('地图标题展示城市和区，缺失字段使用已有行政信息且不重复', () {
    expect(formatMapArea(city: '上海市', district: '浦东新区'), '上海市 · 浦东新区');
    expect(formatMapArea(province: '上海市', district: '浦东新区'), '上海市 · 浦东新区');
    expect(
      formatMapArea(city: '', province: '浙江省', district: '西湖区'),
      '浙江省 · 西湖区',
    );
    expect(formatMapArea(city: '海口市', district: '海口市'), '海口市');
    expect(formatMapArea(district: '朝阳区'), '朝阳区');
    expect(formatMapArea(), '地图');
  });
}
