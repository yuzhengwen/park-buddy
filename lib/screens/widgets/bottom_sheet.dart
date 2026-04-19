import 'package:flutter/material.dart';

/// Template for a persistent draggable bottom sheet.
class DraggableBottomSheet extends StatelessWidget {
  static const initialSize = 0.25;
  static const cornerRadius = 28.0;

  final DraggableScrollableController sheetController;
  final String? title;
  final int? itemCount;
  final Widget Function(BuildContext, int, ScrollController)? itemBuilder;
  final String emptyText;

  const DraggableBottomSheet({
    super.key,
    required this.sheetController,
    this.title,
    this.itemCount,
    this.itemBuilder,
    this.emptyText = 'No items.',
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.1,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.1, initialSize, 0.5, 1.0],
      controller: sheetController,
      builder: (context, scrollController) => AnimatedBuilder(
        animation: sheetController,
        builder: (context, child) {
          final size = sheetController.isAttached
              ? sheetController.size
              : initialSize;
          final t = ((size - 0.9) / 0.1).clamp(0.0, 1.0);
          final radius = cornerRadius * (1 - t);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 16),
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
        child: ListView.builder(
          controller: scrollController,
          itemCount: 1 + (itemCount == null || itemCount == 0 ? 1 : itemCount!),
          itemBuilder: (context, index) {
            if (index == 0) return _SheetHeader(title: title);

            if (itemCount == null || itemCount == 0) {
              return Center(
                child: Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.38),
                      ),
                ),
              );
            }

            return itemBuilder?.call(context, index - 1, scrollController);
          },
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String? title;

  const _SheetHeader({this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        // Drag handle
        Padding(
          padding: const .symmetric(vertical: 12),
          child: Container(
            alignment: .center,
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: .circular(2),
              ),
            ),
          ),
        ),

        // Title
        if (title != null)
          Align(
            alignment: .centerLeft,
            child: Padding(
              padding: const .all(16),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
      ],
    );
  }
}
