import 'package:flutter/material.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.radiusController,
    required this.isSearchingLocation,
    required this.searchText,
    required this.onApply,
    required this.onOpenSettings,
  });

  final TextEditingController searchController;
  final TextEditingController radiusController;
  final bool isSearchingLocation;
  final String searchText;
  final VoidCallback onApply;
  final VoidCallback onOpenSettings;
  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  String? _getRadiusError() {
    final radius = double.tryParse(widget.radiusController.text.trim());
    if (radius != null && radius > 1.0) {
      return 'Max 1 km';
    }
    return null;
  }
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
                    controller: widget.searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Place, address, postal code, or block no.',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: widget.searchText.isEmpty
                          ? null
                          : IconButton(
                              onPressed: widget.searchController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => widget.onApply(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: widget.radiusController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Km',
                      hintText: '1',
                      errorText: _getRadiusError(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => widget.onApply(),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: widget.isSearchingLocation ? null : widget.onApply,
                    child: Text(widget.isSearchingLocation ? '...' : 'Go'),
                  ),
                ),
                IconButton(
                  onPressed: widget.onOpenSettings,
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
