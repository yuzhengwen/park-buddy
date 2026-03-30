import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.radiusController,
    required this.isSearchingLocation,
    required this.isTracking,
    required this.searchText,
    required this.statusMessage,
    required this.searchCenterLabel,
    required this.onApply,
    required this.onOpenSettings,
  });

  final TextEditingController searchController;
  final TextEditingController radiusController;
  final bool isSearchingLocation;
  final bool isTracking;
  final String searchText;
  final String statusMessage;
  final String? searchCenterLabel;
  final VoidCallback onApply;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Place, address, postal code, or block no.',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isEmpty
                          ? null
                          : IconButton(
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => onApply(),
                  ),
                ),

                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: isSearchingLocation ? null : onApply,
                    child: Text(isSearchingLocation ? '...' : 'Go'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isTracking ? Icons.gps_fixed : Icons.location_off,
                  color: isTracking ? Colors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    searchCenterLabel == null
                        ? statusMessage
                        : 'Search area: $searchCenterLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 75,
                  child: TextField(
                    controller: radiusController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Km',
                      hintText: '1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => onApply(),
                  ),
                ),
                IconButton(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings),
                  tooltip: 'Open app settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
