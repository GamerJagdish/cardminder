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

  final List<String> _networks = ['Visa', 'Mastercard', 'RuPay', 'Amex', 'Discover'];

  @override
  void initState() {
    super.initState();
    final card = widget.cardToEdit;
    _nameController = TextEditingController(text: card?.cardName ?? '');
    _digitsController = TextEditingController(text: card?.lastFourDigits ?? '');
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
        lastFourDigits: digits.isNotEmpty ? digits : null,
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
            lastFourDigits: digits.isNotEmpty ? digits : null,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;
    final dateFormat = DateFormat('dd-MM-yyyy');

    final previewCard = CreditCard(
      id: widget.cardToEdit?.id ?? 'preview',
      cardName: _nameController.text.isNotEmpty
          ? _nameController.text
          : 'Card Nickname',
      lastFourDigits: _digitsController.text,
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

              // LAST 4 DIGITS INPUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(text: 'LAST 4 DIGITS (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _digitsController,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '0000',
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // NETWORK SELECTOR PILLS (Edge-to-Edge Horizontal Scroll)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: _FieldLabel(text: 'NETWORK'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final net = _networks[index];
                    final isSelected = _selectedNetwork == net;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedNetwork = net),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryNavy
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            net,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
