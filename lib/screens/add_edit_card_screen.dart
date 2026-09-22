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
  int _customRgbColorValue = AppTheme.defaultCustomRgbCardColor.toARGB32();
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

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _monthFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();

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

    _nameFocus.addListener(() => setState(() {}));
    _monthFocus.addListener(() => setState(() {}));
    _yearFocus.addListener(() => setState(() {}));

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
    _nameFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
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
                      backgroundColor: context.colors.surfaceSubtle,
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
                      foregroundColor: AppTheme.pureBlack,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 14.0),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: _handleBackNavigation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.circleButtonBg,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            isEditing ? 'Edit Card' : 'Add New Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              shadows: AppTheme.textShadowAmbient(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
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
                      // CARD CAROUSEL SLIDER
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
                                                : context.colors.border),
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

                            const SizedBox(height: 16),

                            // NICKNAME INPUT
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormField<String>(
                                initialValue: _nameController.text,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (val) {
                                  if (_nameController.text.trim().isEmpty) {
                                    return 'Please enter a nickname';
                                  }
                                  return null;
                                },
                                builder: (fieldState) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FloatingPillField(
                                        label: 'Card nickname',
                                        controller: _nameController,
                                        focusNode: _nameFocus,
                                        hasError: fieldState.hasError,
                                        child: TextField(
                                          controller: _nameController,
                                          focusNode: _nameFocus,
                                          onChanged: (val) {
                                            fieldState.didChange(val);
                                            setState(() {});
                                          },
                                          cursorColor: AppTheme.accentSky,
                                          cursorWidth: 2.0,
                                          cursorRadius:
                                              const Radius.circular(1.0),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      if (fieldState.hasError)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 18.0, top: 5.0),
                                          child: Text(
                                            fieldState.errorText!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.accentRose,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // EXP. MONTH & EXP. YEAR (Row)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: FormField<String>(
                                      initialValue: _monthController.text,
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (val) {
                                        if (_monthController.text.trim() ==
                                            '0') {
                                          return 'Enter 1–12';
                                        }
                                        return null;
                                      },
                                      builder: (fieldState) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FloatingPillField(
                                              label: 'Exp. month',
                                              controller: _monthController,
                                              focusNode: _monthFocus,
                                              hasError: fieldState.hasError,
                                              child: TextField(
                                                controller: _monthController,
                                                focusNode: _monthFocus,
                                                maxLength: 2,
                                                keyboardType:
                                                    TextInputType.number,
                                                cursorColor:
                                                    AppTheme.accentSky,
                                                cursorWidth: 2.0,
                                                cursorRadius:
                                                    const Radius.circular(
                                                        1.0),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                inputFormatters: const [
                                                  _MonthInputFormatter(),
                                                ],
                                                onChanged: (val) {
                                                  fieldState.didChange(val);
                                                  setState(() {});
                                                  if (val.length == 2) {
                                                    _yearFocus.requestFocus();
                                                  }
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  filled: false,
                                                  fillColor:
                                                      Colors.transparent,
                                                  counterText: '',
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                ),
                                              ),
                                            ),
                                            if (fieldState.hasError)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 18.0, top: 5.0),
                                                child: Text(
                                                  fieldState.errorText!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.accentRose,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _FloatingPillField(
                                      label: 'Exp. year',
                                      controller: _yearController,
                                      focusNode: _yearFocus,
                                      child: TextField(
                                        controller: _yearController,
                                        focusNode: _yearFocus,
                                        maxLength: 2,
                                        keyboardType: TextInputType.number,
                                        cursorColor: AppTheme.accentSky,
                                        cursorWidth: 2.0,
                                        cursorRadius:
                                            const Radius.circular(1.0),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          counterText: '',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // DEACTIVATION TIMELINE & LAST TRANSACTION DATE (Row)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _InPillFieldContainer(
                                      label: 'Deactivation timeline',
                                      child: DropdownButtonFormField<int>(
                                        initialValue:
                                            _selectedDeactivationDays,
                                        isExpanded: true,
                                        isDense: true,
                                        borderRadius: BorderRadius.circular(20),
                                        dropdownColor: isDark
                                            ? const Color(0xFF1E2430)
                                            : Colors.white,
                                        elevation: 8,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        ),
                                        icon: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
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
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _InPillFieldContainer(
                                      label: 'Last transaction',
                                      onTap: _pickDate,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dateFormat
                                                  .format(_selectedDate),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                        backgroundColor: context.colors.buttonPrimaryBg,
                        foregroundColor: context.colors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Add Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.buttonPrimaryFg,
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

class _InPillFieldContainer extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  const _InPillFieldContainer({
    required this.label,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? const Color(0xFF1E2430)
        : const Color(0xFFF1F5F9);

    final labelColor = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    final container = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: labelColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            height: 24,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: container,
      );
    }

    return container;
  }
}

class _FloatingPillField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;
  final bool hasError;

  const _FloatingPillField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.child,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isFloating = focusNode.hasFocus || controller.text.isNotEmpty;

        final fillColor = isDark
            ? const Color(0xFF1E2430)
            : const Color(0xFFF1F5F9);

        final mutedColor = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!focusNode.hasFocus) {
              focusNode.requestFocus();
            }
          },
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(20),
              border: hasError
                  ? Border.all(color: AppTheme.accentRose, width: 1.2)
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Floating Label
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  top: isFloating ? 8 : 20,
                  child: IgnorePointer(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: isFloating ? 11.5 : 15,
                        fontWeight:
                            isFloating ? FontWeight.w500 : FontWeight.w400,
                        color: mutedColor,
                        letterSpacing: isFloating ? 0.2 : 0.0,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),

                // Input Field
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  height: 24,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: isFloating ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !isFloating,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

