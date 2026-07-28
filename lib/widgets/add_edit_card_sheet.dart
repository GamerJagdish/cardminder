import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';
import '../providers/card_provider.dart';
import '../theme/app_theme.dart';

class AddEditCardSheet extends ConsumerStatefulWidget {
  final CreditCard? cardToEdit;

  const AddEditCardSheet({super.key, this.cardToEdit});

  @override
  ConsumerState<AddEditCardSheet> createState() => _AddEditCardSheetState();
}

class _AddEditCardSheetState extends ConsumerState<AddEditCardSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _digitsController;
  late TextEditingController _bankController;

  bool _isTodaySelected = true;
  late DateTime _selectedDate;
  int _selectedColorIndex = 0;

  final List<String> _popularSuggestions = [
    'HDFC Regalia',
    'ICICI Sapphiro',
    'SBI SimplyClick',
    'Axis Ace',
    'Chase Sapphire',
    'Amex Platinum',
    'Amazon Pay ICICI',
  ];

  @override
  void initState() {
    super.initState();
    final card = widget.cardToEdit;
    _nameController = TextEditingController(text: card?.cardName ?? '');
    _digitsController = TextEditingController(text: card?.lastFourDigits ?? '');
    _bankController = TextEditingController(text: card?.bankName ?? '');
    _selectedColorIndex = card?.colorIndex ?? 0;

    if (card != null) {
      _selectedDate = card.lastTransactionDate;
      final now = DateTime.now();
      _isTodaySelected = card.lastTransactionDate.year == now.year &&
          card.lastTransactionDate.month == now.month &&
          card.lastTransactionDate.day == now.day;
    } else {
      _selectedDate = DateTime.now();
      _isTodaySelected = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _digitsController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryViolet,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isTodaySelected = false;
      });
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final digits = _digitsController.text.trim();
    final bank = _bankController.text.trim();

    final txDate = _isTodaySelected ? DateTime.now() : _selectedDate;

    if (widget.cardToEdit != null) {
      final updated = widget.cardToEdit!.copyWith(
        cardName: name,
        lastFourDigits: digits.isNotEmpty ? digits : null,
        bankName: bank.isNotEmpty ? bank : null,
        lastTransactionDate: txDate,
        colorIndex: _selectedColorIndex,
      );
      ref.read(cardNotifierProvider.notifier).updateCard(updated);
    } else {
      ref.read(cardNotifierProvider.notifier).addCard(
            cardName: name,
            lastFourDigits: digits.isNotEmpty ? digits : null,
            bankName: bank.isNotEmpty ? bank : null,
            lastTransactionDate: txDate,
            colorIndex: _selectedColorIndex,
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet header handle & title
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Credit Card' : 'Add New Credit Card',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card Name Input
              Text(
                'Card Name *',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. HDFC Regalia Gold',
                  prefixIcon: Icon(Icons.credit_card, color: AppTheme.primaryViolet),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter card name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Quick Name Suggestions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularSuggestions.map((suggestion) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(suggestion),
                        selected: _nameController.text == suggestion,
                        labelStyle: TextStyle(
                          color: _nameController.text == suggestion
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 12,
                        ),
                        backgroundColor: AppTheme.bgDark,
                        selectedColor: AppTheme.primaryViolet,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _nameController.text = suggestion;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Last 4 Digits & Bank Name (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last 4 Digits (Optional)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _digitsController,
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: '4321',
                            counterText: '',
                            prefixIcon: Icon(Icons.pin, color: AppTheme.secondaryCyan),
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
                        Text(
                          'Bank Name (Optional)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bankController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'e.g. HDFC',
                            counterText: '',
                            prefixIcon: Icon(Icons.account_balance,
                                color: AppTheme.accentGold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Transaction Date Choice (Today vs Add Date)
              Text(
                'Last Transaction Date *',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Option 1: TODAY
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isTodaySelected = true;
                          _selectedDate = DateTime.now();
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isTodaySelected
                              ? AppTheme.primaryViolet
                              : AppTheme.bgDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isTodaySelected
                                ? AppTheme.primaryViolet
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.today_rounded,
                              color: _isTodaySelected ? Colors.white : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Today',
                              style: TextStyle(
                                color:
                                    _isTodaySelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Option 2: ADD DATE / SELECT DATE
                  Expanded(
                    child: InkWell(
                      onTap: _pickCustomDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isTodaySelected
                              ? AppTheme.secondaryCyan
                              : AppTheme.bgDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isTodaySelected
                                ? AppTheme.secondaryCyan
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: !_isTodaySelected ? Colors.white : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              !_isTodaySelected ? 'Selected Date' : 'Add Date',
                              style: TextStyle(
                                color:
                                    !_isTodaySelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Date confirmation banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppTheme.accentGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isTodaySelected
                            ? 'Timer starts today (${dateFormat.format(DateTime.now())}). Deactivates in 365 days.'
                            : 'Timer starts from ${dateFormat.format(_selectedDate)}.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Card Color Gradient Picker
              Text(
                'Card Style Theme',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.cardGradients.length,
                  itemBuilder: (context, index) {
                    final colors = AppTheme.cardGradients[index];
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: colors),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.first.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Card & Start 365d Timer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
