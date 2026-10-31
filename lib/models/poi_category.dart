import 'package:flutter/material.dart';
import 'primary_tag.dart';

/// Map POIs use AMap's typecode, independently of personal collection labels.
enum PoiCategory {
  food('餐饮', Icons.restaurant_outlined, Color(0xFFC58D45)),
  coffee('咖啡', Icons.local_cafe_outlined, Color(0xFFAD805C)),
  bar('酒吧', Icons.local_bar_outlined, Color(0xFF9676AB)),
  hotel('住宿', Icons.hotel_outlined, Color(0xFF8976AA)),
  sight('景点', Icons.park_outlined, Color(0xFF54977D)),
  residence('住宅', Icons.home_outlined, Color(0xFF8192A5)),
  office('办公', Icons.business_outlined, Color(0xFF8192A5)),
  shopping('购物', Icons.shopping_bag_outlined, Color(0xFFB37A98)),
  health('医疗', Icons.local_hospital_outlined, Color(0xFFB36E77)),
  education('科教', Icons.school_outlined, Color(0xFF7C8EAC)),
  transport('交通', Icons.directions_transit_outlined, Color(0xFF6D94BD)),
  finance('金融', Icons.account_balance_outlined, Color(0xFF85989C)),
  service('生活服务', Icons.storefront_outlined, Color(0xFF9398A1)),
  other('地点', Icons.place_outlined, Color(0xFF9398A1));

  const PoiCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static PoiCategory fromAmap(String code, String description) {
    // typecode is authoritative; textual fallback is only for missing/unknown codes.
    if (code.startsWith('0505')) return coffee;
    if (code.startsWith('0504')) return bar;
    if (code.startsWith('05')) return food;
    if (code.startsWith('10')) return hotel;
    if (code.startsWith('11')) return sight;
    if (code.startsWith('1203')) return residence;
    if (code.startsWith('12') || code.startsWith('17')) return office;
    if (code.startsWith('06')) return shopping;
    if (code.startsWith('09')) return health;
    if (code.startsWith('14')) return education;
    if (code.startsWith('15')) return transport;
    if (code.startsWith('16')) return finance;
    if (code.startsWith('07')) return service;
    if (description.contains('住宅') || description.contains('小区')) {
      return residence;
    }
    if (description.contains('办公') ||
        description.contains('商务') ||
        description.contains('公司')) {
      return office;
    }
    if (description.contains('咖啡')) return coffee;
    if (description.contains('酒吧')) return bar;
    if (description.contains('餐饮') || description.contains('餐厅')) return food;
    if (description.contains('住宿') || description.contains('酒店')) return hotel;
    if (description.contains('公园') ||
        description.contains('风景') ||
        description.contains('景点')) {
      return sight;
    }
    return other;
  }

  PrimaryTag get suggestedTag => switch (this) {
    food => PrimaryTag.food,
    coffee => PrimaryTag.coffee,
    bar => PrimaryTag.bar,
    hotel => PrimaryTag.hotel,
    sight => PrimaryTag.sight,
    _ => PrimaryTag.other,
  };
}
