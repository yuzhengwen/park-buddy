import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/UI/map_search_bar.dart';
import 'package:park_buddy/UI/page_with_sheet.dart';
import 'package:park_buddy/controllers/map_tab_controller.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/UI/bottom_sheet.dart';
import 'package:park_buddy/UI/map.dart';
import 'package:park_buddy/UI/carpark_list_item.dart';
import 'package:park_buddy/services/location_search_service.dart';
import 'package:park_buddy/utils/math_utils.dart';

/// Layout of a map with a draggable sheet of locations.
class MapWithSheet extends StatefulWidget {
  final MapTabController mapTabController;
  final String? sheetTitle;
  final Widget? floatingActionButton;
  final LatLng? initialPosition;
  final String confirmCarparkText;
  final void Function(Carpark)? onConfirmCarpark;

  const MapWithSheet({
    super.key,
    required this.mapTabController,
    this.sheetTitle,
    this.floatingActionButton,
    this.initialPosition,
    this.confirmCarparkText = 'Confirm',
    this.onConfirmCarpark,
  });

  @override
  State<MapWithSheet> createState() => _MapWithSheetState();
}

class _MapWithSheetState extends State<MapWithSheet> with TickerProviderStateMixin {
  final _sheetController = DraggableScrollableController();
  late final _mapController = AnimatedMapController(vsync: this);
  final _searchController = SearchController();
  final _whenMapReady = Completer<void>();

  StreamSubscription? _locationEnabledStream;
  LocalHistoryEntry? _carparkDetailsSubscreen;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _locationEnabledStream = widget.mapTabController.location.locationAvailableStream
        .where((isEnabled) => isEnabled)
        .listen(_onLocationEnabled);
    if (widget.initialPosition != null) {
      widget.mapTabController.visibleCarparksCentre = widget.initialPosition;
    }
  }

  @override
  void dispose() {
    _locationEnabledStream?.cancel();
    _sheetController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onLocationEnabled(bool isEnabled) async {
    await _whenMapReady.future;
    final selected = widget.mapTabController.selectedCarpark;
    final userLocation = widget.mapTabController.location.currentLocation;

    final pos = selected?.position ?? widget.initialPosition ?? userLocation;
    if (pos != null) _mapController.animateTo(dest: pos);
  }

  void _onMapReady() {
    if (!_whenMapReady.isCompleted) {
      _whenMapReady.complete();
    }
  }

  void _onSearchDone(String text) {
  if (!_searchController.isAttached) return;

  if (_searchController.text.isEmpty) _onSearchClear();
}

  void _onSearchClear() {
    if (!_searchController.isAttached) return;

    _searchController.clear();
    widget.mapTabController.visibleCarparksCentre = null;
  }

  void _onSelectSearchResult(SearchResult res) {
    widget.mapTabController.visibleCarparksCentre = res.position;
    _mapController.animateTo(dest: res.position);
    _searchController.closeView(null);
  }

  void _recenterOnUser() {
    final userLocation = widget.mapTabController.location.currentLocation;

    if (userLocation != null) {
      _mapController.animateTo(dest: userLocation);
    }
  }

  void _openCarparkDetails(Carpark carpark) {
    widget.mapTabController.selectedCarpark = carpark;
    _mapController.animateTo(dest: carpark.position);
    _resetSheetSize();

    // Don't recreate LocalHistoryEntry if already present
    if (_carparkDetailsSubscreen != null) return;

    _carparkDetailsSubscreen = LocalHistoryEntry(
      onRemove: _closeCarparkDetails,
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_carparkDetailsSubscreen!);
  }

  void _closeCarparkDetails() {
    setState(() {
      widget.mapTabController.selectedCarpark = null;
      _carparkDetailsSubscreen = null;
    });
    _resetSheetSize();
  }

  void _resetSheetSize() {
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollController!.jumpTo(0);
    }

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        DraggableBottomSheet.initialSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onConfirmSelectedCarpark() {
    if (widget.mapTabController.selectedCarpark == null) return;
    widget.onConfirmCarpark?.call(widget.mapTabController.selectedCarpark!);
  }

  static List<_CarparkListItemData> _createDetailsList(Carpark carpark, double? distance) {
    return [
      _CarparkListItemData('Carpark no.', value: carpark.carParkNo),
      _CarparkListItemData('Type', value: carpark.carParkType),
      _CarparkListItemData('Short-term parking', value: carpark.shortTermParking),
      _CarparkListItemData(
        'Lots available',
        value: carpark.availability != null
            ? '${carpark.availability!.lotsAvailable}/${carpark.availability!.totalLots}'
            : 'n/a',
      ),
      _CarparkListItemData(
        'Distance',
        value: distance != null
            ? '${distance.toStringAsFixed(2)} km'
            : 'n/a',
      ),
      _CarparkListItemData(
        'Fee Structure',
        special: IconButton(
          onPressed: null,    // TODO: fee structure popup
          icon: const Icon(Icons.info_outline),
        ),
      ),
    ];
  }

  Widget _buildMainBottomSheet(List<Carpark> carparks, LatLng? userLocation) {
    return DraggableBottomSheet(
      sheetController: _sheetController,
      title: widget.sheetTitle,
      emptyText: 'No car parks nearby.',
      itemCount: carparks.length,
      itemBuilder: (context, index, scrollController) {
        _scrollController = scrollController;

        return CarparkListItem(
          carpark: carparks[index],
          distanceKm: userLocation != null
              ? MathUtils.distanceKm(userLocation, carparks[index].position)
              : null,
          onItemSelect: widget.onConfirmCarpark,
          onItemInfo: _openCarparkDetails,
        );
      },
    );
  }

  Widget _buildDetailsBottomSheet(Carpark selected, LatLng? userLocation) {
    final distance = userLocation != null
        ? MathUtils.distanceKm(userLocation, selected.position)
        : null;
    final items = _createDetailsList(selected, distance);

    return DraggableBottomSheet(
      sheetController: _sheetController,
      title: selected.address,
      itemCount: 1 + items.length,
      itemBuilder: (context, index, scrollController) {
        _scrollController = scrollController;

        if (index == 0) return _buildDetailsButtonRow(context);

        final item = items[index - 1];

        return ListTile(
          title: Text(item.name),
          subtitle: item.value != null ? Text(item.value!) : null,
          trailing: item.special,
        );
      },
    );
  }

  Widget _buildDetailsButtonRow(BuildContext context) {
    return Padding(
      padding: const .fromLTRB(16, 0, 16, 16),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')
            ),
          ),
          Expanded(
            child: FilledButton(
              onPressed: _onConfirmSelectedCarpark,
              child: Text(widget.confirmCarparkText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(Carpark? selected, LatLng? userLocation) {
    return Column(
      crossAxisAlignment: .end,
      spacing: 8,
      children: [
        _RecenterButton(
          onPressed: userLocation != null ? _recenterOnUser : null,
        ),

        if (widget.floatingActionButton != null && selected == null)
          widget.floatingActionButton!,
      ],
    );
  }

  void _showSliderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set range'),
        content: ListenableBuilder(
          listenable: widget.mapTabController,
          builder: (context, child) => Column(
            mainAxisSize: .min,
            children: [
              Text('${widget.mapTabController.radiusKm.toStringAsFixed(2)} km'),
              Slider(
                value: widget.mapTabController.radiusKm,
                min: 0.01,
                max: 1.00,
                onChanged: (newValue) {
                  widget.mapTabController.radiusKm = newValue;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.mapTabController,
      builder: (context, child) {
        final selected = widget.mapTabController.selectedCarpark;
        final userLocation = widget.mapTabController.location.currentLocation;
        final carparks = widget.mapTabController.visibleCarparks;

        return PageWithSheet(
          sheetController: _sheetController,
          bottomSheet: selected == null
              ? _buildMainBottomSheet(carparks, userLocation)
              : _buildDetailsBottomSheet(selected, userLocation),
          floatingButtons: _buildFloatingButtons(selected, userLocation),
          content: selected == null
              ? MapSearchBar(
                  mapTabController: widget.mapTabController,
                  searchController: _searchController,
                  onSearchDone: _onSearchDone,
                  onTapRangeButton: _showSliderDialog,
                  onTapSearchClearButton: _onSearchClear,
                  onTapSearchResult: _onSelectSearchResult,
                )
              : null,
          background: child,
        );
      },
      child: CarparkMap(
        mapController: _mapController.mapController,
        mapTabController: widget.mapTabController,
        onTapMarker: _openCarparkDetails,
        onMapReady: _onMapReady,
      ),
    );
  }
}

/// Button that recentres the map on user.
class _RecenterButton extends StatelessWidget {
  final void Function()? onPressed;

  const _RecenterButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.small(
      onPressed: onPressed,
      heroTag: null,
      shape: CircleBorder(),
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      child: Icon(
        onPressed != null ? Icons.my_location : Icons.location_disabled,
      ),
    );
  }
}

class _CarparkListItemData {
  final String name;
  final String? value;
  final Widget? special;

  _CarparkListItemData(this.name, {this.value, this.special});
}
