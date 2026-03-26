import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/transaction.dart';
import '../providers/transactions_provider.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';

// ── Categorias ────────────────────────────────────────────────────────────────

const _expenseCategories = <(String, String, String)>[
  ('food', '🛒', 'Comida'),
  ('transport', '🚗', 'Transporte'),
  ('entertainment', '🎬', 'Entretenimiento'),
  ('health', '🏥', 'Salud'),
  ('clothing', '👗', 'Ropa'),
  ('housing', '🏠', 'Hogar'),
  ('services', '📱', 'Servicios'),
  ('education', '📚', 'Educacion'),
  ('other', '➕', 'Otros'),
];

const _incomeCategories = <(String, String, String)>[
  ('salary', '💰', 'Salario'),
  ('freelance', '💻', 'Freelance'),
  ('business', '🏪', 'Negocio'),
  ('investment', '📈', 'Inversion'),
  ('gift', '🎁', 'Regalo'),
  ('other', '➕', 'Otros'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  String _amountText = '';
  String _description = '';
  String _category = _expenseCategories.first.$1;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  String? _selectedAccountId;

  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<(String, String, String)> get _categories =>
      _type == TransactionType.expense ? _expenseCategories : _incomeCategories;

  bool get _canSave {
    if (_amountText.isEmpty) return false;
    final value = double.tryParse(_amountText.replaceAll(',', '.'));
    return value != null && value > 0;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.parse(_amountText.replaceAll(',', '.'));
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final transaction = Transaction(
      id: '',
      userId: userId,
      amount: amount,
      type: _type,
      category: _category,
      description: _description.trim().isEmpty ? null : _description.trim(),
      date: _date,
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(transactionNotifierProvider.notifier).add(
        transaction,
        accountId: _selectedAccountId,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Widget> _buildAccountSelector(FinPaColors c, ColorScheme cs) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    return accountsAsync.maybeWhen(
      data: (accounts) {
        final spendable =
            accounts.where((a) => a.type.isSpendable).toList();
        if (spendable.length <= 1) return const [];
        _selectedAccountId ??= spendable
            .firstWhere((a) => a.isDefault,
                orElse: () => spendable.first)
            .id;
        return [
          _SectionLabel(label: '¿De qué cuenta?', cs: cs),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedAccountId,
                onChanged: (v) => setState(() => _selectedAccountId = v),
                items: spendable
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            children: [
                              Text(a.type.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a.name,
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ];
      },
      orElse: () => [const SizedBox(height: 8)],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nueva transaccion',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 1. Selector Gasto / Ingreso
            _TypeSelector(
              current: _type,
              onChanged: (t) {
                setState(() {
                  _type = t;
                  _category = _categories.first.$1;
                });
              },
              c: c,
              cs: cs,
            ),
            const SizedBox(height: 28),

            // 2. Campo Monto
            _AmountField(
              controller: _amountCtrl,
              onChanged: (v) => setState(() => _amountText = v),
              c: c,
              cs: cs,
            ),
            const SizedBox(height: 24),

            // 3. Descripcion
            _SectionLabel(label: 'Descripcion', cs: cs),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              onChanged: (v) => setState(() => _description = v),
              maxLines: 1,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Descripcion (opcional)',
              ),
            ),
            const SizedBox(height: 24),

            // 4. Categorias
            _SectionLabel(label: 'Categoria', cs: cs),
            const SizedBox(height: 12),
            _CategoryPicker(
              categories: _categories,
              selected: _category,
              onChanged: (cat) => setState(() => _category = cat),
              c: c,
              cs: cs,
            ),
            const SizedBox(height: 24),

            // 5. Fecha
            _SectionLabel(label: 'Fecha', cs: cs),
            const SizedBox(height: 8),
            _DateRow(
              date: _date,
              onTap: _pickDate,
              c: c,
              cs: cs,
            ),
            const SizedBox(height: 24),

            // 5.5 — Selector de cuenta (solo si hay más de 1)
            ..._buildAccountSelector(c, cs),

            // 6. Boton guardar (el selector ya añade su propio SizedBox(height:32))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave && !_isSaving ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Guardar transaccion',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final TransactionType current;
  final ValueChanged<TransactionType> onChanged;
  final FinPaColors c;
  final ColorScheme cs;

  const _TypeSelector({
    required this.current,
    required this.onChanged,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'Gasto',
            active: current == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
            c: c,
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            label: 'Ingreso',
            active: current == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
            c: c,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final FinPaColors c;
  final ColorScheme cs;

  const _TypeButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B5BDB) : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: active ? null : Border.all(color: c.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FinPaColors c;
  final ColorScheme cs;

  const _AmountField({
    required this.controller,
    required this.onChanged,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'RD\$',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: c.muted,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B5BDB), width: 1.5),
              ),
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final List<(String, String, String)> categories;
  final String selected;
  final ValueChanged<String> onChanged;
  final FinPaColors c;
  final ColorScheme cs;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final (id, emoji, name) = cat;
        final isSelected = selected == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B5BDB) : cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: isSelected ? null : Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Date row ──────────────────────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  final FinPaColors c;
  final ColorScheme cs;

  const _DateRow({
    required this.date,
    required this.onTap,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMMM yyyy', 'es_ES').format(date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatted,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Cambiar',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B5BDB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }
}
