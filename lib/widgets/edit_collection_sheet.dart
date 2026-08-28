import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collection_view.dart';
import '../state/collection_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/uuid.dart';
import 'collection_form_fields.dart';
import 'sheet_chrome.dart';

/// 编辑收藏 Sheet：预填标签 / 打卡状态 / 备注，保存后更新记录。
class EditCollectionSheet extends StatefulWidget {
  final CollectionView view;

  const EditCollectionSheet({super.key, required this.view});

  @override
  State<EditCollectionSheet> createState() => _EditCollectionSheetState();
}

class _EditCollectionSheetState extends State<EditCollectionSheet> {
  final _formKey = GlobalKey<CollectionFormFieldsState>();

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    final updated = widget.view.collection.copyWith(
      primaryTag: form.tag,
      secondaryTags: form.secondaryTags,
      note: form.note,
      images: form.images,
      visitedStatus: form.visited ? 'visited' : 'pending',
      updatedAt: nowIso8601(),
    );
    final ok = await context.read<CollectionProvider>().update(updated);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('编辑收藏', style: AppText.sectionTitle),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('×',
                              style:
                                  TextStyle(fontSize: 20, color: AppColors.stone)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.view.name, style: AppText.placeName),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  CollectionFormFields(
                    key: _formKey,
                    initialTag: widget.view.tag,
                    initialVisited: widget.view.visited,
                    initialNote: widget.view.note,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text('保存修改',
                      style: AppText.chip
                          .copyWith(color: AppColors.warmWhite, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
