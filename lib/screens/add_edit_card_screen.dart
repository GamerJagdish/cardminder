import 'package:flutter/material.dart';
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
  late DateTime _selectedDate;



  @override
  void initState() {
    super.initState();
    final card = widget.cardToEdit;
    _nameController = TextEditingController(text: card?.cardName ?? '');
    _digitsController = TextEditingController(text: card?.lastFourDigits ?? '0001');
    _monthController = TextEditingController(text: card?.expiryMonth ?? '12');
    _yearController = TextEditingController(text: card?.expiryYear ?? '28');

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
      );
      ref.read(cardNotifierProvider.notifier).updateCard(updated);
    } else {
      ref.read(cardNotifierProvider.notifier).addCard(
            cardName: name,
            lastFourDigits: digits.isNotEmpty ? digits : '0001',
            lastTransactionDate: _selectedDate,
            colorIndex: _selectedColorIndex,
            cardType: _cardType,
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
              ),
            );
      }
    }

    Navigator.pop(context);
  }

  void _showRgbColorPickerDialog(BuildContext context) {
    Color currentColor = Color(_customRgbColorValue);

    double r = (currentColor.r * 255.0).clamp(0.0, 255.0);
    double g = (currentColor.g * 255.0).clamp(0.0, 255.0);
    double b = (currentColor.b * 255.0).clamp(0.0, 255.0);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final activeColor = Color.from(
            alpha: 1.0,
            red: r / 255.0,
            green: g / 255.0,
            blue: b / 255.0,
          );
          final hexString =
              '#${r.toInt().toRadixString(16).padLeft(2, '0')}${g.toInt().toRadixString(16).padLeft(2, '0')}${b.toInt().toRadixString(16).padLeft(2, '0')}'
                  .toUpperCase();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Custom RGB Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Color Preview Container
                  Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hexString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Red Slider
                  Row(
                    children: [
                      const Text('R',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      Expanded(
                        child: Slider(
                          value: r,
                          min: 0,
                          max: 255,
                          activeColor: Colors.red,
                          onChanged: (val) => setDialogState(() => r = val),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${r.toInt()}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // Green Slider
                  Row(
                    children: [
                      const Text('G',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green)),
                      Expanded(
                        child: Slider(
                          value: g,
                          min: 0,
                          max: 255,
                          activeColor: Colors.green,
                          onChanged: (val) => setDialogState(() => g = val),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${g.toInt()}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // Blue Slider
                  Row(
                    children: [
                      const Text('B',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      Expanded(
                        child: Slider(
                          value: b,
                          min: 0,
                          max: 255,
                          activeColor: Colors.blue,
                          onChanged: (val) => setDialogState(() => b = val),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${b.toInt()}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final argbInt = activeColor.toARGB32();
                  setState(() {
                    _customRgbColorValue = argbInt;
                    _selectedColorIndex = argbInt;
                  });
                  if (_currentPage != AppTheme.cardThemes.length) {
                    _pageController.animateToPage(
                      AppTheme.cardThemes.length,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Apply Color'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDigitsDialog(BuildContext context) {
    final tempController = TextEditingController(
      text: _digitsController.text.isNotEmpty ? _digitsController.text : '0001',
    );
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Last 4 Digits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0001',
                counterText: '',
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryNavy, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final val = tempController.text.trim();
              setState(() {
                _digitsController.text = val.isNotEmpty ? val : '0001';
              });
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save Digits'),
          ),
        ],
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

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            onTap: isCustomRgbPage
                                ? () => _showRgbColorPickerDialog(context)
                                : null,
                          ),
                          if (isCustomRgbPage)
                            Positioned(
                              top: 14,
                              right: 16,
                              child: GestureDetector(
                                onTap: () =>
                                    _showRgbColorPickerDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.palette_outlined,
                                          size: 16, color: AppTheme.primaryNavy),
                                      SizedBox(width: 4),
                                      Text(
                                        'Custom RGB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                            ? AppTheme.primaryNavy
                            : (isCustomDot
                                ? AppTheme.primaryNavy.withValues(alpha: 0.4)
                                : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 20),

              // LAST TRANSACTION DATE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFormat.format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppTheme.textDark),
                          ],
                        ),
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
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add Card',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
