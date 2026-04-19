import 'package:flutter/material.dart';
import 'package:park_buddy/screens/widgets/bottom_sheet.dart';

/// Layout of a page with a draggable bottom sheet.
class PageWithSheet extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final Widget? background;
  final Widget? content;
  final Widget? bottomSheet;
  final Widget? floatingButtons;

  const PageWithSheet({
    super.key,
    required this.sheetController,
    this.background,
    this.content,
    this.bottomSheet,
    this.floatingButtons,
  });

  static double _sheetSizeFrac(DraggableScrollableController controller) {
    return controller.isAttached ? controller.size : DraggableBottomSheet.initialSize;
  }

  static double _sheetSize(DraggableScrollableController controller, double parentHeight) {
    return parentHeight * _sheetSizeFrac(controller);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          // 1. Background
          AnimatedBuilder(
            animation: sheetController,
            builder: (context, child) {
              final offset = -0.5 * _sheetSize(sheetController, constraints.maxHeight);

              return Transform.translate(
                offset: Offset(0.0, offset),
                child: child,
              );
            },
            child: background,
          ),

          // 2. Content
          ?content,

          // 3. Bottom sheet
          ?bottomSheet,

          // 4. Floating buttons
          AnimatedBuilder(
            animation: sheetController,
            builder: (context, child) {
              final offset = -_sheetSize(sheetController, constraints.maxHeight);
              final isVisible = _sheetSizeFrac(sheetController) <= 0.5;

              return Positioned(
                bottom: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(-16, offset - 16),
                  child: AnimatedScale(
                    scale: isVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    ),
                  )
                ),
              );
            },
            child: floatingButtons,
          ),
        ],
      ),
    );
  }
}
