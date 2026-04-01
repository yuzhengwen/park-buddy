import 'package:flutter/material.dart';

/// Encapsulates logic for widgets that float above a bottom sheet.
///
/// Must be used within a stack.
class BottomSheetFloatingAnchor extends StatelessWidget {
  final DraggableScrollableController _sheetController;
  final List<Widget> _children;

  const BottomSheetFloatingAnchor({
    super.key,
    required DraggableScrollableController sheetController,
    required List<Widget> children,
  }) : _sheetController = sheetController,
       _children = children;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sheetController,
      builder: (context, child) {
        final offset = _sheetController.isAttached
            ? _sheetController.pixels + 16.0
            : 16.0;

        final isVisible = _sheetController.isAttached
            ? _sheetController.size <= 0.5
            : true;

        return Positioned(
          right: 16,
          bottom: offset,
          child: AnimatedScale(
            scale: isVisible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: child!,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: _children,
      ),
    );
  }
}
