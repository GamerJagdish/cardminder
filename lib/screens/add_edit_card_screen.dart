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

  int _selectedColorIndex = 0;
  String _selectedNetwork = 'Visa';
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
    _selectedColorIndex = card?.colorIndex ?? 0;
    _selectedNetwork = card?.network ?? 'Visa';
    _selectedDate = card?.lastTransactionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _digitsController.dispose();
    _monthController.dispose();
    _yearController.dispose();
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
            cardType: 'Debit Card',
          );
      // Also update full card fields
      final list = ref.read(cardNotifierProvider).cards;
      if (list.isNotEmpty) {
        final created = list.firstWhere(
          (c) => c.cardName == name,
          orElse: () => list.last,
        );
        ref.read(cardNotifierProvider.notifier).updateCard(
              created.copyWith(
                network: _selectedNetwork,
                expiryMonth: month.isNotEmpty ? month : '12',
                expiryYear: year.isNotEmpty ? year : '28',
              ),
            );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;
    final dateFormat = DateFormat('dd-MM-yyyy');

    // Dynamic Live Preview Card object
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
      cardType: 'Debit Card',
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
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Credit Card Preview
              CreditCardView(card: previewCard, isInteractive: false),

              const SizedBox(height: 24),

              // CARD COLOR SELECTOR
              const _FieldLabel(text: 'CARD COLOR'),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.cardThemes.length,
                  itemBuilder: (context, index) {
                    final colors = AppTheme.cardThemes[index];
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.first,
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryNavy, width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // NICKNAME INPUT
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

              const SizedBox(height: 20),

              // LAST 4 DIGITS INPUT
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

              const SizedBox(height: 20),

              // NETWORK SELECTOR PILLS (Horizontal Scrollable Pills for Perfect Fit)
              const _FieldLabel(text: 'NETWORK'),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
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
              Row(
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

              const SizedBox(height: 20),

              // LAST TRANSACTION DATE
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

              const SizedBox(height: 32),

              // Bottom Save Button
              SizedBox(
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
