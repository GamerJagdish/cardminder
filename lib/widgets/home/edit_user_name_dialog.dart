import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EditUserNameDialog extends StatefulWidget {
  final String currentName;
  final ValueChanged<String> onSave;

  const EditUserNameDialog({
    super.key,
    required this.currentName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentName,
    required ValueChanged<String> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (dialogCtx) => EditUserNameDialog(
        currentName: currentName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditUserNameDialog> createState() => _EditUserNameDialogState();
}

class _EditUserNameDialogState extends State<EditUserNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty) {
      widget.onSave(newName);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final availableWidth = mediaQuery.size.width - 48.0;
    final dialogWidth = availableWidth.clamp(300.0, 400.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isLandscape || mediaQuery.size.height < 500 ? 12 : 24,
      ),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
          Theme.of(context).cardTheme.color,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          minWidth: dialogWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Your Name',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 25,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  counterText: '',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryAccentDark
                            : AppTheme.primaryNavy,
                        foregroundColor:
                            isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
