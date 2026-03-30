import 'dart:core';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/utils/math_utils.dart';

// Bottom sheet holding the list of carpark locations
class CarparkPickerBottomSheet extends StatefulWidget {
  static const initialSheetSize = 0.25;
  final List<Carpark> carparks;
  final void Function(Carpark carpark)? onItemSelect;
  final DraggableScrollableController controller;
  final LatLng? userLocation;

  const CarparkPickerBottomSheet({
    super.key,
    required this.carparks,
    this.onItemSelect,
    required this.controller,
    this.userLocation,
  });

  @override
  State<CarparkPickerBottomSheet> createState() => _CarparkPickerBottomSheetState();
}

class _CarparkPickerBottomSheetState extends State<CarparkPickerBottomSheet> {
  final _sheetSize = ValueNotifier(CarparkPickerBottomSheet.initialSheetSize);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: CarparkPickerBottomSheet.initialSheetSize,
      minChildSize: 0.1,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.25, 0.5, 1.0],
      controller: widget.controller,
      builder: (context, scrollController) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            _sheetSize.value = notification.extent;
            return false;
          },
          child: ValueListenableBuilder<double>(
            valueListenable: _sheetSize,
            builder: (context, size, child) {
              final t = ((size - 0.9) / 0.1).clamp(0.0, 1.0);
              final radius = 28.0 * (1 - t);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: _SheetContent(
              scrollController: scrollController,
              carparks: widget.carparks,
              userLocation: widget.userLocation,
              onItemSelect: (carpark) async {
                widget.onItemSelect?.call(carpark);
                scrollController.jumpTo(0);
                await widget.controller.animateTo(
                  0.25,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<Carpark> carparks;
  final LatLng? userLocation;
  final void Function(Carpark carpark)? onItemSelect;

  const _SheetContent({
    required this.scrollController,
    required this.carparks,
    this.userLocation,
    this.onItemSelect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nearest HDB Car Parks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (carparks.isNotEmpty)
          SliverList.builder(
            itemCount: carparks.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _CarparkCard(
                  onItemSelect: onItemSelect,
                  carpark: carparks[index],
                  userLocation: userLocation,
                ),
              );
            },
          )
        else
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No carparks found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CarparkCard extends StatelessWidget {
  final void Function(Carpark carpark)? onItemSelect;
  final Carpark carpark;
  final LatLng? userLocation;

  const _CarparkCard({
    required this.onItemSelect,
    required this.carpark,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    final carparkNo = 'Car park: ${carpark.carParkNo}';
    final distanceKm = userLocation != null
        ? ' • ${MathUtils.distanceKm(userLocation!, carpark.position).toStringAsFixed(2)} km'
        : '';
    final lotsLabel = carpark.availability != null && carpark.availability!.lotsAvailable == 1
        ? 'lot'
        : 'lots';
    final numLots = carpark.availability != null
        ? '${carpark.availability!.lotsAvailable}\n$lotsLabel'
        : 'n/a';

    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          debugPrint('card tapped');
          onItemSelect?.call(carpark);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carpark.address,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('$carparkNo $distanceKm'),
                    Text('${carpark.carParkType} • ${carpark.shortTermParking}',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  numLots,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        alignment: Alignment.center,
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
