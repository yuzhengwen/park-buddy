import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:park_buddy/models/carpark.dart';
import 'package:park_buddy/utils/math_utils.dart';

class CarparkListPanel extends StatelessWidget {
  const CarparkListPanel({
    super.key,
    required this.visibleCarparks,
    required this.isLoadingCarparks,
    required this.isListCollapsed,
    required this.loadError,
    required this.listOrigin,
    required this.selectedCarparkNo,
    required this.onToggleCollapse,
    required this.onCarparkTap,
    required this.onRetry,
  });

  final List<Carpark> visibleCarparks;
  final bool isLoadingCarparks;
  final bool isListCollapsed;
  final String? loadError;
  final LatLng listOrigin;
  final String? selectedCarparkNo;
  final VoidCallback onToggleCollapse;
  final void Function(Carpark) onCarparkTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: isListCollapsed ? 82 : 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _PanelHandle(
              carparkCount: visibleCarparks.length,
              isCollapsed: isListCollapsed,
              onToggle: onToggleCollapse,
            ),
            if (!isListCollapsed)
              Expanded(
                child: _CarparkListBody(
                  visibleCarparks: visibleCarparks,
                  isLoadingCarparks: isLoadingCarparks,
                  loadError: loadError,
                  listOrigin: listOrigin,
                  selectedCarparkNo: selectedCarparkNo,
                  onCarparkTap: onCarparkTap,
                  onRetry: onRetry,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _PanelHandle extends StatelessWidget {
  const _PanelHandle({
    required this.carparkCount,
    required this.isCollapsed,
    required this.onToggle,
  });

  final int carparkCount;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Nearest HDB Car Parks ($carparkCount)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: Text(isCollapsed ? 'Expand' : 'Collapse'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarparkListBody extends StatelessWidget {
  const _CarparkListBody({
    required this.visibleCarparks,
    required this.isLoadingCarparks,
    required this.loadError,
    required this.listOrigin,
    required this.selectedCarparkNo,
    required this.onCarparkTap,
    required this.onRetry,
  });

  final List<Carpark> visibleCarparks;
  final bool isLoadingCarparks;
  final String? loadError;
  final LatLng listOrigin;
  final String? selectedCarparkNo;
  final void Function(Carpark) onCarparkTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingCarparks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry Data Load'),
              ),
            ],
          ),
        ),
      );
    }

    if (visibleCarparks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No HDB car parks match the current search and radius.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: visibleCarparks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final carpark = visibleCarparks[index];
        final km = MathUtils.distanceKm(listOrigin, carpark.position);
        final isSelected = carpark.carParkNo == selectedCarparkNo;

        return _CarparkListTile(
          index: index,
          carpark: carpark,
          distanceKm: km,
          isSelected: isSelected,
          onTap: () => onCarparkTap(carpark),
        );
      },
    );
  }
}

class _CarparkListTile extends StatelessWidget {
  const _CarparkListTile({
    required this.index,
    required this.carpark,
    required this.distanceKm,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final Carpark carpark;
  final double distanceKm;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carpark.address,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Car park: ${carpark.carParkNo}'),
                    const SizedBox(height: 4),
                    Text(
                      '${distanceKm.toStringAsFixed(2)} km away'
                      '${carpark.availability == null ? '' : ' • ${carpark.availability!.lotsAvailable} lots free'}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${carpark.carParkType} • ${carpark.shortTermParking}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
