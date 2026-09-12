import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/card_form/card_color_picker.dart';
import '../widgets/card_form/card_digits_dialog.dart';
import '../widgets/credit_card_view.dart';

/// Screen for creating or editing credit and debit card profiles.
class AddEditCardScreen extends ConsumerStatefulWidget {
  final CreditCard? cardToEdit;

  const AddEditCardScreen({super.key, this.cardToEdit});

  @override
  ConsumerState<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends ConsumerState<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _cardId;
  late TextEditingController _nameController;
  late TextEditingController _digitsController;
  late TextEditingController _monthController;
  late TextEditingController _yearController;
  late PageController _pageController;

  int _currentPage = 0;
  int _selectedColorIndex = 0;
  int _customRgbColorValue = const Color(0xFFE11D48).toARGB32();
  String _selectedNetwork = 'Visa';
  String _cardType = 'Credit Card';
  int _selectedDeactivationDays = 365;
  late DateTime _selectedDate;

  late String _initialName;
  late String _initialDigits;
  late String _initialMonth;
  late String _initialYear;
  late int _initialColorIndex;
  late String _initialNetwork;
  late String _initialCardType;
  late int _initialDeactivationDays;
  late DateTime _initialDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final card = widget.cardToEdit;
    _cardId = card?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: card?.cardName ?? '')
      ..addListener(() => setState(() {}));
    _digitsController = TextEditingController(text: card?.lastFourDigits ?? '0001')
      ..addListener(() => setState(() {}));
    _monthController = TextEditingController(text: card?.expiryMonth ?? '12')
      ..addListener(() => setState(() {}));
    _yearController = TextEditingController(text: card?.expiryYear ?? '28')
      ..addListener(() => setState(() {}));

    if (card != null) {
      _selectedColorIndex = card.colorIndex;
      if (_selectedColorIndex >= 0 &&
          _selectedColorIndex < AppTheme.cardThemes.length) {
        _currentPage = _selectedColorIndex;
      } else {
        _currentPage = AppTheme.cardThemes.length;
        _customRgbColorValue = _selectedColorIndex;
      }
      _selectedNetwork = card.network;
      _cardType = card.cardType;
      _selectedDeactivationDays = card.deactivationPeriodDays;
      _selectedDate = card.lastTransactionDate;
    } else {
      _selectedColorIndex = 0;
      _currentPage = 0;
      _selectedDate = DateTime.now();
    }

    _pageController = PageController(initialPage: _currentPage);

    _initialName = _nameController.text;
    _initialDigits = _digitsController.text;
    _initialMonth = _monthController.text;
    _initialYear = _yearController.text;
    _initialColorIndex = _selectedColorIndex;
    _initialNetwork = _selectedNetwork;
    _initialCardType = _cardType;
    _initialDeactivationDays = _selectedDeactivationDays;
    _initialDate = _selectedDate;
  }

  bool get _hasUnsavedChanges {
    return _nameController.text != _initialName ||
        _digitsController.text != _initialDigits ||
        _monthController.text != _initialMonth ||
        _yearController.text != _initialYear ||
        _selectedColorIndex != _initialColorIndex ||
        _selectedNetwork != _initialNetwork ||
        _cardType != _initialCardType ||
        _selectedDeactivationDays != _initialDeactivationDays ||
        _selectedDate != _initialDate;
  }

  Future<void> _handleBackNavigation() async {
    if (_hasUnsavedChanges && !_isSaving) {
      final shouldDiscard = await _showUnsavedChangesDialog(context);
      if (shouldDiscard && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _digitsController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final card = CreditCard(
      id: _cardId,
      cardName: _nameController.text.trim(),
      lastFourDigits: _digitsController.text.trim(),
      lastTransactionDate: _selectedDate,
      colorIndex: _selectedColorIndex,
      cardType: _cardType,
      network: _selectedNetwork,
      expiryMonth: _monthController.text.trim(),
      expiryYear: _yearController.text.trim(),
      deactivationPeriodDays: _selectedDeactivationDays,
    );

    if (widget.cardToEdit == null) {
      await ref.read(cardNotifierProvider.notifier).addCard(
            id: card.id,
            cardName: card.cardName,
            lastFourDigits: card.lastFourDigits,
            lastTransactionDate: card.lastTransactionDate,
            colorIndex: card.colorIndex,
            bankName: card.bankName,
            cardType: card.cardType,
            network: card.network,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            deactivationPeriodDays: card.deactivationPeriodDays,
          );
    } else {
      await ref.read(cardNotifierProvider.notifier).updateCard(card);
    }

    // Give the form exit fade time to settle cleanly
    await Future.delayed(const Duration(milliseconds: 140));

    if (!mounted) return;

    // Ensure downstream frames render the newly added card before popping
    await WidgetsBinding.instance.endOfFrame;

    if (mounted) {
      Navigator.pop(context, _cardId);
    }
  }

  Future<bool> _showUnsavedChangesDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).cardTheme.color,
        surfaceTintColor: Colors.transparent,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.accentAmber,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them and go back?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Keep Editing',
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
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Discard',
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
    );
    return result ?? false;
  }

  Future<void> _showDigitsDialog(BuildContext context) async {
    final digits = await CardDigitsDialog.show(context, _digitsController.text);
    if (digits != null && mounted) {
      setState(() {
        _digitsController.text = digits;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;
    final dateFormat = DateFormat('dd-MM-yyyy');

    final previewCard = CreditCard(
      id: _cardId,
      cardName: _nameController.text.isNotEmpty
          ? _nameController.text
          : 'Card Nickname',
      lastFourDigits:
          _digitsController.text.isNotEmpty ? _digitsController.text : '0001',
      lastTransactionDate: _selectedDate,
      colorIndex: _selectedColorIndex,
      network: _selectedNetwork,
      expiryMonth:
          _monthController.text.isNotEmpty ? _monthController.text : 'MM',
      expiryYear: _yearController.text.isNotEmpty ? _yearController.text : 'YY',
      cardType: _cardType,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showUnsavedChangesDialog(context);
        if (shouldDiscard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _handleBackNavigation,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ),
          title: Text(isEditing ? 'Edit Card' : 'Add New Card'),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CARD CAROUSEL SLIDER (Swipe to select card color)
                      AnimatedOpacity(
                        opacity: _isSaving ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: _FieldLabel(text: 'SELECT CARD COLOR'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 195,
                        child: PageView.builder(
                          controller: _pageController,
                          clipBehavior: Clip.none,
                          itemCount: AppTheme.cardThemes.length + 1,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                              if (index < AppTheme.cardThemes.length) {
                                _selectedColorIndex = index;
                              } else {
                                _selectedColorIndex = _customRgbColorValue;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final isCustomRgbPage =
                                index == AppTheme.cardThemes.length;
                            final cardColor =
                                isCustomRgbPage ? _customRgbColorValue : index;
                            final cardForPage =
                                previewCard.copyWith(colorIndex: cardColor);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Stack(
                                children: [
                                  CreditCardView(
                                    card: cardForPage,
                                    isInteractive: false,
                                    heroTag: index == _currentPage
                                        ? 'card-hero-$_cardId'
                                        : null,
                                    onCardTypeTap: () {
                                      setState(() {
                                        _cardType = _cardType == 'Credit Card'
                                            ? 'Debit Card'
                                            : 'Credit Card';
                                      });
                                    },
                                    onDigitsTap: () => _showDigitsDialog(context),
                                    onNetworkSelected: (net) {
                                      setState(() => _selectedNetwork = net);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      AnimatedOpacity(
                        opacity: _isSaving ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),

                            // Page Indicator Dots (. . . . . . 🎨)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                AppTheme.cardThemes.length + 1,
                                (index) {
                                  final isSelected = _currentPage == index;
                                  final isCustomDot =
                                      index == AppTheme.cardThemes.length;
                                  final primaryColor =
                                      Theme.of(context).colorScheme.primary;

                                  return GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: isSelected ? 22 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor
                                            : (isCustomDot
                                                ? primaryColor.withValues(
                                                    alpha: 0.4)
                                                : (isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFCBD5E1))),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // INLINE COLOR PICKER (visible only on custom color page)
                            CardColorPicker(
                              customRgbColorValue: _customRgbColorValue,
                              onColorChanged: (newColor) {
                                setState(() {
                                  _customRgbColorValue = newColor;
                                  _selectedColorIndex = _customRgbColorValue;
                                });
                              },
                              isVisible:
                                  _currentPage == AppTheme.cardThemes.length,
                            ),

                            const SizedBox(height: 20),

                            // NICKNAME INPUT
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(text: 'NICKNAME (REQUIRED)'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Swiggy HDFC',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please enter a nickname';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // EXP. MONTH & EXP. YEAR (Row)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            text: 'EXP. MONTH (OPTIONAL)'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _monthController,
                                          maxLength: 2,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: const [
                                            _MonthInputFormatter(),
                                          ],
                                          validator: (val) {
                                            if (val != null && val.trim() == '0') {
                                              return 'Enter 1–12';
                                            }
                                            return null;
                                          },
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            hintText: 'MM',
                                            counterText: '',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            text: 'EXP. YEAR (OPTIONAL)'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _yearController,
                                          maxLength: 2,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          decoration: const InputDecoration(
                                            hintText: 'YY',
                                            counterText: '',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // DEACTIVATION TIMELINE & LAST TRANSACTION DATE (Row)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            text: 'DEACTIVATION TIMELINE'),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<int>(
                                          initialValue:
                                              _selectedDeactivationDays,
                                          isExpanded: true,
                                          dropdownColor: isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 16),
                                            fillColor: Theme.of(context)
                                                .inputDecorationTheme
                                                .fillColor,
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 90,
                                              child: Text('3 Months',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                            DropdownMenuItem(
                                              value: 180,
                                              child: Text('6 Months',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                            DropdownMenuItem(
                                              value: 270,
                                              child: Text('9 Months',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                            DropdownMenuItem(
                                              value: 365,
                                              child: Text('1 Year',
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedDeactivationDays = val;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _FieldLabel(
                                            text: 'LAST TRANSACTION DATE'),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: _pickDate,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .inputDecorationTheme
                                                  .fillColor,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    dateFormat
                                                        .format(_selectedDate),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sticky Bottom Save Button
            SafeArea(
              top: false,
              child: AnimatedOpacity(
                opacity: _isSaving ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryAccentDark
                            : AppTheme.primaryNavy,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Restricts user input in the month field to digits 1-12 (allowing 01-12, 1-12, and 03).
class _MonthInputFormatter extends TextInputFormatter {
  const _MonthInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    // Only allow numeric digits
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return oldValue;
    }

    // Maximum 2 digits
    if (text.length > 2) {
      return oldValue;
    }

    // Single digit: '0' through '9' allowed while typing (e.g. typing '0' then '3' for '03')
    if (text.length == 1) {
      return newValue;
    }

    // 2 digits: must be between 1 and 12 ('01' through '12')
    final val = int.tryParse(text);
    if (val == null || val < 1 || val > 12) {
      return oldValue;
    }

    return newValue;
  }
}

