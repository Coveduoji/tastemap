import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/sync_manager.dart';
import 'state/collection_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 注册生命周期监听：App 退到后台时触发坚果云自动备份
  WidgetsBinding.instance.addObserver(SyncManager());
  runApp(
    ChangeNotifierProvider(
      create: (_) => CollectionProvider()..load(),
      child: const TasteMapApp(),
    ),
  );
}
