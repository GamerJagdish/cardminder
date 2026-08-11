import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_card_view.dart';

class AddEditCardScreen extends ConsumerStatefulWidget {
  final CreditCard? cardToEdit;

  const AddEditCardScreen({super.key, this.cardToEdit});

  @override
  ConsumerState<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends ConsumerState<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
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
    _nameController = TextEditingController(text: card?.cardName ?? '');
    _digitsController = TextEditingController(text: card?.lastFourDigits ?? '0001');
    _monthController = TextEditingController(text: card?.expiryMonth ?? '12');
    _yearController = TextEditingController(text: card?.expiryYear ?? '28');
    _selectedDeactivationDays = card?.deactivationPeriodDays ?? 365;

    if (card != null) {
      if (card.colorIndex >= AppTheme.cardThemes.length) {
        _customRgbColorValue = card.colorIndex;
        _selectedColorIndex = card.colorIndex;
        _currentPage = AppTheme.cardThemes.length;
      } else {
        _selectedColorIndex = card.colorIndex;
        _currentPage = card.colorIndex;
      }
    } else {
      _selectedColorIndex = 0;
      _currentPage = 0;
    }

    _pageController = PageController(initialPage: _currentPage);
    _selectedNetwork = card?.network ?? 'Visa';
    _cardType = card?.cardType ?? 'Credit Card';
    _selectedDate = card?.lastTransactionDate ?? DateTime.now();

    _initialName = _nameController.text.trim();
    _initialDigits = _digitsController.text.trim();
    _initialMonth = _monthController.text.trim();
    _initialYear = _yearController.text.trim();
    _initialColorIndex = _selectedColorIndex;
    _initialNetwork = _selectedNetwork;
    _initialCardType = _cardType;
    _initialDeactivationDays = _selectedDeactivationDays;
    _initialDate = _selectedDate;
  }

  bool get _hasUnsavedChanges {
    final nameChanged = _nameController.text.trim() != _initialName;
    final digitsChanged = _digitsController.text.trim() != _initialDigits;
    final monthChanged = _monthController.text.trim() != _initialMonth;
    final yearChanged = _yearController.text.trim() != _initialYear;
    final colorChanged = _selectedColorIndex != _initialColorIndex;
    final networkChanged = _selectedNetwork != _initialNetwork;
    final cardTypeChanged = _cardType != _initialCardType;
    final deactivationChanged =
        _selectedDeactivationDays != _initialDeactivationDays;
    final dateChanged = !_isSameDate(_selectedDate, _initialDate);

    return nameChanged ||
        digitsChanged ||
        monthChanged ||
        yearChanged ||
        colorChanged ||
        networkChanged ||
        cardTypeChanged ||
        deactivationChanged ||
        dateChanged;
  }

  bool _isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
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
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    _isSaving = true;

    final name = _nameController.text.trim();
    final digits = _digitsController.text.trim();
    final month = _monthController.text.trim();
    final year = _yearController.text.trim();

    if (widget.cardToEdit != null) {
      final updated = widget.cardToEdit!.copyWith(
        cardName: name,
        lastFourDigits: digits.isNotEmpty ? digits : '0001',
        lastTransactionDate: _selectedDate,
        colorIndex: _selectedColorIndex,
        network: _selectedNetwork,
        cardType: _cardType,
        expiryMonth: month.isNotEmpty ? month : '12',
        expiryYear: year.isNotEmpty ? year : '28',
        deactivationPeriodDays: _selectedDeactivationDays,
      );
      ref.read(cardNotifierProvider.notifier).updateCard(updated);
    } else {
      ref.read(cardNotifierProvider.notifier).addCard(
            cardName: name,
            lastFourDigits: digits.isNotEmpty ? digits : '0001',
            lastTransactionDate: _selectedDate,
            colorIndex: _selectedColorIndex,
            cardType: _cardType,
            deactivationPeriodDays: _selectedDeactivationDays,
          );
      final list = ref.read(cardNotifierProvider).cards;
      if (list.isNotEmpty) {
        final created = list.firstWhere(
          (c) => c.cardName == name,
          orElse: () => list.last,
        );
        ref.read(cardNotifierProvider.notifier).updateCard(
              created.copyWith(
                network: _selectedNetwork,
                cardType: _cardType,
                expiryMonth: month.isNotEmpty ? month : '12',
                expiryYear: year.isNotEmpty ? year : '28',
                deactivationPeriodDays: _selectedDeactivationDays,
              ),
            );
      }
    }

    Navigator.pop(context);
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                      backgroundColor: AppTheme.accentRose,
                      foregroundColor: Colors.white,
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

  Future<void> _handleBackNavigation() async {
    if (!_hasUnsavedChanges || _isSaving) {
      Navigator.pop(context);
      return;
    }
    final shouldDiscard = await _showUnsavedChangesDialog(context);
    if (shouldDiscard && mounted) {
      Navigator.pop(context);
    }
  }

  void _showDigitsDialog(BuildContext context) {
    final tempController = TextEditingController(
      text: _digitsController.text == '0000' ? '' : _digitsController.text,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).cardTheme.color,
        child: Padding(
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
                controller: tempController,
                autofocus: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final val = tempController.text.trim();
                  setState(() {
                    _digitsController.text =
                        val.isNotEmpty ? val : '0001';
                  });
                  Navigator.pop(dialogCtx);
                },
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
                      onPressed: () => Navigator.pop(dialogCtx),
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
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final val = tempController.text.trim();
                        setState(() {
                          _digitsController.text =
                              val.isNotEmpty ? val : '0001';
                        });
                        Navigator.pop(dialogCtx);
                      },
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;
    final dateFormat = DateFormat('dd-MM-yyyy');

    final previewCard = CreditCard(
      id: widget.cardToEdit?.id ?? 'preview',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD CAROUSEL SLIDER (Swipe to select card color)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: _FieldLabel(text: 'SELECT CARD COLOR'),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 195,
                child: PageView.builder(
                  controller: _pageController,
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
                    final isCustomRgbPage = index == AppTheme.cardThemes.length;
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

              const SizedBox(height: 12),

              // Page Indicator Dots (. . . . . . 🎨)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AppTheme.cardThemes.length + 1, (index) {
                  final isSelected = _currentPage == index;
                  final isCustomDot = index == AppTheme.cardThemes.length;
                  final primaryColor = Theme.of(context).colorScheme.primary;

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isCustomDot
                                ? primaryColor.withValues(alpha: 0.4)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1))),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // INLINE COLOR PICKER (visible only on custom color page)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Title and Hex Code Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.palette_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Pick Your Color',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            // Hex Value Display Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                '#${Color(_customRgbColorValue).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main Color Picker Area
                        SizedBox(
                          width: double.infinity,
                          height: 170,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ColorPickerArea(
                              HSVColor.fromColor(Color(_customRgbColorValue)),
                              (hsv) {
                                setState(() {
                                  _customRgbColorValue =
                                      hsv.toColor().toARGB32();
                                  _selectedColorIndex = _customRgbColorValue;
                                });
                              },
                              PaletteType.hsvWithHue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Slider & SQUARE Color Preview Row
                        Row(
                          children: [
                            // SQUARE Color Preview Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Color(_customRgbColorValue),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(_customRgbColorValue)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Hue Slider
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ColorPickerSlider(
                                  TrackType.hue,
                                  HSVColor.fromColor(
                                      Color(_customRgbColorValue)),
                                  (hsv) {
                                    setState(() {
                                      _customRgbColorValue =
                                          hsv.toColor().toARGB32();
                                      _selectedColorIndex =
                                          _customRgbColorValue;
                                    });
                                  },
                                  displayThumbColor: true,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Quick Preset Color Swatches
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Color(0xFF0F172A), // Slate Dark
                            const Color(0xFF1E1B4B), // Midnight Indigo
                            const Color(0xFF065F46), // Deep Emerald
                            const Color(0xFF831843), // Rich Magenta
                            const Color(0xFF1E3A8A), // Ocean Navy
                            const Color(0xFF581C87), // Royal Violet
                            const Color(0xFF991B1B), // Crimson Red
                            const Color(0xFFB45309), // Amber Gold
                            const Color(0xFF15803D), // Forest Green
                            const Color(0xFF0284C7), // Sky Blue
                            const Color(0xFFBE185D), // Rose Pink
                          ].map((swatch) {
                            final isSelected =
                                _customRgbColorValue == swatch.toARGB32();
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _customRgbColorValue = swatch.toARGB32();
                                  _selectedColorIndex = _customRgbColorValue;
                                });
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: swatch,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: isSelected ? 2.5 : 0,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState: _currentPage == AppTheme.cardThemes.length
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 20),

              // NICKNAME INPUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(text: 'EXP. MONTH (OPTIONAL)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _monthController,
                            maxLength: 2,
                            keyboardType: TextInputType.number,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(text: 'EXP. YEAR (OPTIONAL)'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(text: 'DEACTIVATION TIMELINE'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedDeactivationDays,
                            isExpanded: true,
                            dropdownColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              fillColor: Theme.of(context)
                                  .inputDecorationTheme
                                  .fillColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 90,
                                child: Text('3 Months',
                                    overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 180,
                                child: Text('6 Months',
                                    overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 270,
                                child: Text('9 Months',
                                    overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 365,
                                child: Text('1 Year',
                                    overflow: TextOverflow.ellipsis),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(text: 'LAST TRANSACTION DATE'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                borderRadius: BorderRadius.circular(16),
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
                                      dateFormat.format(_selectedDate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.calendar_today_outlined,
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

              const SizedBox(height: 32),

              // Bottom Save Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
            ],
          ),
        ),
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
