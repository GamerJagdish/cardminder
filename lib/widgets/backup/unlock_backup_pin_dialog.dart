import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/backup_service.dart';
import '../../theme/app_theme.dart';
import '../common/responsive_dialog.dart';

/// Dialog to enter PIN, decrypt backup file inline, and allow retry immediately inside the dialog if incorrect.
class UnlockBackupPinDialog extends StatefulWidget {
  final File file;

  const UnlockBackupPinDialog({super.key, required this.file});

  @override
  State<UnlockBackupPinDialog> createState() => _UnlockBackupPinDialogState();
}

class _UnlockBackupPinDialogState extends State<UnlockBackupPinDialog> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePin = true;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndUnlock() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit PIN.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final backupData = await BackupService.decryptBackupFile(
        file: widget.file,
        userPin: pin,
      );

      if (mounted) {
        Navigator.of(context).pop(backupData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final verticalPadding =
        isLandscape || mediaQuery.size.height < 500 ? 16.0 : 24.0;

    return ResponsiveDialog(
      minWidth: 320,
      maxWidth: 440,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: verticalPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.accentEmerald.withValues(alpha: isDark ? 0.32 : 0.20),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.key_rounded,
                        color: AppTheme.accentEmerald,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock Backup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter backup PIN to restore',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMuted : AppTheme.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the 4-digit PIN you used when this backup was created to decrypt your card data.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Inline Error Message Card
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRose.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentRose.withValues(alpha: isDark ? 0.35 : 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.accentRose,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentRose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              TextFormField(
                controller: _pinController,
                autofocus: true,
                obscureText: _obscurePin,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _verifyAndUnlock(),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '●●●●',
                  hintStyle: TextStyle(
                    letterSpacing: 10,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textMuted.withValues(alpha: 0.5),
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: context.colors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.colors.border,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: context.colors.border,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.accentRose,
                      width: 1.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.accentRose,
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark ? AppTheme.textMuted : AppTheme.slate600,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.length != 4) {
                    return 'Please enter a 4-digit PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: TextButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.buttonPrimaryBg,
                          foregroundColor: context.colors.buttonPrimaryFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isVerifying ? null : _verifyAndUnlock,
                        child: _isVerifying
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.buttonPrimaryFg,
                                ),
                              )
                            : const Text(
                                'Unlock',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
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
