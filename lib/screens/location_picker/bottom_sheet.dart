import 'dart:core';
import 'package:flutter/material.dart';
import 'package:park_buddy/screens/location_picker/location.dart';


// Bottom sheet holding the list of carpark locations
class CarparkPickerBottomSheet extends StatelessWidget {
  final List<CarparkLocation> _carparks;
  final void Function(CarparkLocation carpark)? _onItemSelect;

  const CarparkPickerBottomSheet({
    super.key,
    required List<CarparkLocation> carparks,
    void Function(CarparkLocation carpark)? onItemSelect,
  }) : _carparks = carparks,
       _onItemSelect = onItemSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          SliverPersistentHeader(
            delegate: DragHandleDelegate(),
            pinned: true,
          ),
          if (_carparks.isNotEmpty)
            SliverList.builder(
              itemCount: _carparks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_carparks[index].name),
                  onTap: () => _onItemSelect?.call(_carparks[index]),
                );
              },
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No carparks found',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ),
        ],
      ),
      snap: true,
      snapSizes: [0.5, 0.9],
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
        margin: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
