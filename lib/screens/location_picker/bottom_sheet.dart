import 'dart:core';
import 'package:flutter/material.dart';
import 'package:park_buddy/models/carpark.dart';

// Bottom sheet holding the list of carpark locations
class CarparkPickerBottomSheet extends StatefulWidget {
  final List<Carpark> _carparks;
  final void Function(Carpark carpark)? _onItemSelect;
  final DraggableScrollableController? controller;

  const CarparkPickerBottomSheet({
    super.key,
    required List<Carpark> carparks,
    void Function(Carpark carpark)? onItemSelect,
    this.controller,
  }) : _carparks = carparks,
       _onItemSelect = onItemSelect;

  @override
  State<CarparkPickerBottomSheet> createState() => _CarparkPickerBottomSheetState();
}

class _CarparkPickerBottomSheetState extends State<CarparkPickerBottomSheet> {
  final _sheetSize = ValueNotifier(0.25);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
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
                duration: const Duration(milliseconds: 50),
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
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                if (widget._carparks.isNotEmpty)
                  SliverList.builder(
                    itemCount: widget._carparks.length,
                    itemBuilder: (context, index) {
                      final carpark = widget._carparks[index];
                      return ListTile(
                        title: Text(carpark.address),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Car park: ${carpark.carParkNo}\n'),
                              // TODO: carpark availability
                              TextSpan(text: '${carpark.carParkType} • ${carpark.shortTermParking}'),
                            ],
                          ),
                        ),
                        onTap: () => widget._onItemSelect?.call(widget._carparks[index]),
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
            )
          ),
        );
      },
    );
  }
}

// Bottom sheet drag handle
class DragHandleDelegate extends SliverPersistentHeaderDelegate {
  final double height = 36;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      alignment: Alignment(0, 0),
      child: Container(
        width: 32,
        height: 4,
        margin: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
