import 'package:flutter/material.dart';
import '../data/external_navigation.dart';
import '../models/collection_view.dart';

Future<void> navigateToPlace(BuildContext context, CollectionView view) async {
  try {
    final result = await ExternalNavigation.open(view);
    if (context.mounted && result == NavigationResult.copied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('地址已复制'), duration: Duration(seconds: 2)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导航暂不可用，请重试')));
    }
  }
}
