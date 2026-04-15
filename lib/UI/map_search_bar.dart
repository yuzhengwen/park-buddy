import 'package:flutter/material.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/services/location_search_service.dart';

class MapSearchBar extends StatelessWidget {
  final SearchController searchController;
  final MapTabController mapTabController;
  final void Function(String) onSearchDone;
  final void Function(BuildContext) onTapRangeButton;
  final void Function() onTapSearchClearButton;
  final void Function(SearchResult res) onTapSearchResult;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.mapTabController,
    required this.onTapRangeButton,
    required this.onTapSearchClearButton,
    required this.onTapSearchResult,
    required this.onSearchDone,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: SearchAnchor.bar(
        searchController: searchController,
        barHintText: 'Search for carparks',
        barPadding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        onSubmitted: onSearchDone,
        barLeading: ListenableBuilder(
          listenable: searchController,
          builder: (context, _) => searchController.text.isEmpty
              ? SizedBox(width: 48, height: 48, child: const Icon(Icons.search))
              : IconButton(
                  onPressed: onTapSearchClearButton,
                  icon: const Icon(Icons.clear),
                ),
        ),
        barTrailing: [
          TextButton.icon(
            onPressed: () => onTapRangeButton(context),
            icon: const Icon(Icons.radar),
            label: ListenableBuilder(
              listenable: mapTabController,
              builder: (context, child) {
                return Text(
                  '${mapTabController.radiusKm.toStringAsFixed(2)} km',
                );
              },
            ),
          ),
        ],
        suggestionsBuilder: (context, searchController) async {
          await mapTabController.search.debouncedLocationSearch(
            searchController.text,
          );
          return mapTabController.search.searchResults.map(
            (res) => ListTile(
              leading: switch (res.source) {
                .carpark => const Icon(Icons.directions_car_filled),
                .building => const Icon(Icons.business),
              },
              title: Text(res.searchVal),
              subtitle: Text(res.address),
              trailing: const Icon(Icons.arrow_outward),
              onTap: () => onTapSearchResult(res),
            ),
          );
        },
      ),
    );
  }
}
