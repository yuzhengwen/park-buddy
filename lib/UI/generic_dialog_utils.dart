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

  /// Shows a text input dialog and returns the entered string, or null if cancelled.
  ///
  /// - [initialValue]: pre-fills the text field (e.g. current family name)
  /// - [maxLength]: optional character limit shown as a counter
  /// - [validator]: optional fn — return an error string to block submission,
  ///   return null to allow it. Input is always trimmed before validation.
  /// - [sanitize]: optional fn to transform the value before returning it
  ///   (e.g. collapse whitespace, capitalize). Runs after validation passes.
  ///
  /// Example:
  /// ```dart
  /// final newName = await DialogUtils.prompt(
  ///   context: context,
  ///   title: 'Edit Family Name',
  ///   initialValue: familyName,
  ///   maxLength: 50,
  ///   validator: (v) => v.isEmpty ? 'Name cannot be empty' : null,
  ///   sanitize: (v) => v.replaceAll(RegExp(r'\s+'), ' '),
  /// );
  /// if (newName != null) { ... }
  /// ```
  static Future<String?> prompt({
    required BuildContext context,
    required String title,
    String? initialValue,
    String hintText = '',
    String? labelText,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    int? maxLength,
    String? Function(String value)? validator,
    String Function(String value)? sanitize,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx, null),
                child: Text(cancelLabel),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () {
                        final trimmed = controller.text.trim();
                        final error = validator?.call(trimmed);
                        if (error != null) {
                          setDialogState(() => errorText = error);
                          return;
                        }
                        setDialogState(() {
                          isSaving = true;
                          errorText = null;
                        });
                        final result = sanitize?.call(trimmed) ?? trimmed;
                        Navigator.pop(ctx, result);
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(confirmLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}
