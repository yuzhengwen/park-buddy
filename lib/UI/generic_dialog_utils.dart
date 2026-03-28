import 'package:flutter/material.dart';

class GenericDialogUtils {
  /// Shows a confirm dialog and returns true if confirmed, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final confirmed = await GenericDialogUtils.confirm(
  ///   context: context,
  ///   title: 'Delete Family?',
  ///   message: 'This cannot be undone.',
  ///   confirmLabel: 'Delete',
  ///   destructive: true,
  /// );
  /// if (confirmed) { ... }
  /// ```
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  confirmLabel,
                  style: TextStyle(
                    color: destructive ? Colors.red : null,
                    fontWeight: destructive ? FontWeight.bold : null,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<String> prompt({
    required BuildContext context,
    required String title,
    String hintText = '',
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
  }) async {
    final controller = TextEditingController();
    return await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hintText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        '';
  }
}
