import 'package:flutter/material.dart';
import '../data/poi_search.dart';
import '../theme/colors.dart';

/// Uses Flutter's standard search route; only the actual POI query is app logic.
class PlaceSearch extends SearchDelegate<Poi?> {
  final double latitude, longitude;
  String _last = '';
  Future<List<Poi>>? _results;
  PlaceSearch(this.latitude, this.longitude) : super(searchFieldLabel: '地点、地址');
  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));
  @override
  Widget buildSuggestions(BuildContext context) => _body(context);
  @override
  Widget buildResults(BuildContext context) => _body(context);
  Widget _body(BuildContext context) {
    final text = query.trim();
    if (text.isEmpty) return const SizedBox();
    if (_last != text || _results == null) {
      _last = text;
      _results = Future<void>.delayed(const Duration(milliseconds: 300)).then(
        (_) => _last == text
            ? PoiSearchService.searchByName(text, latitude, longitude)
            : <Poi>[],
      );
    }
    return FutureBuilder<List<Poi>>(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () {
                _results = null;
                showResults(context);
              },
              child: const Text('重试'),
            ),
          );
        }
        final values = snapshot.data ?? [];
        if (values.isEmpty) return const Center(child: Text('没有找到地点'));
        return ListView.builder(
          itemCount: values.length,
          itemBuilder: (_, i) {
            final poi = values[i];
            return ListTile(
              leading: Icon(poi.category.icon, color: poi.category.color),
              title: Text(poi.name),
              subtitle: Text(
                [poi.city, poi.addr].where((s) => s.isNotEmpty).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.stone),
              onTap: () => close(context, poi),
            );
          },
        );
      },
    );
  }
}
