import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Modal dialog allowing the user to update the last 4 digits of a card.
class CardDigitsDialog extends StatefulWidget {
  final String initialDigits;

  const CardDigitsDialog({
    super.key,
    required this.initialDigits,
  });

  static Future<String?> show(BuildContext context, String initialDigits) {
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => CardDigitsDialog(initialDigits: initialDigits),
    );
  }

  @override
  State<CardDigitsDialog> createState() => _CardDigitsDialogState();
}

class _CardDigitsDialogState extends State<CardDigitsDialog> {
  late final TextEditingController _tempController;

  @override
  void initState() {
    super.initState();
    _tempController = TextEditingController(
      text: widget.initialDigits == '0000' ? '' : widget.initialDigits,
    );
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  void _submit() {
    final val = _tempController.text.trim();
    Navigator.pop(context, val.isNotEmpty ? val : '0001');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final availableWidth = mediaQuery.size.width - 48.0;
    final dialogWidth = availableWidth.clamp(300.0, 400.0);

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
                      Icons.pin_outlined,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Last 4 Digits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the last 4 digits of your card:',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tempController,
                autofocus: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0001',
                  counterText: '',
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
