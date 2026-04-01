import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../data/accounts_repository.dart';
import '../providers/accounts_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AddBankAccountScreen
// ─────────────────────────────────────────────────────────────────────────────

class AddBankAccountScreen extends ConsumerStatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  ConsumerState<AddBankAccountScreen> createState() =>
      _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends ConsumerState<AddBankAccountScreen> {
  String? _selectedBank;
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _onBankSelected(String bankName) {
    setState(() => _selectedBank = bankName);
    // Pre-llenar el nombre con el banco seleccionado si está vacío
    if (_nameCtrl.text.isEmpty) {
      _nameCtrl.text = bankName;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      _showBankError();
      return;
    }

    final name = _nameCtrl.text.trim();
    final balance =
        double.tryParse(_balanceCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final notifier = ref.read(accountNotifierProvider.notifier);
    await notifier.addBankAccount(
      name: name,
      bankName: _selectedBank!,
      initialBalance: balance,
    );

    final state = ref.read(accountNotifierProvider);
    if (!mounted) return;

    state.when(
      data: (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuenta añadida ✓',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      error: (e, _) => _showError(e.toString()),
      loading: () {},
    );
  }

  void _showBankError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Elige tu banco primero',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).extension<FinPaColors>()!.expense,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final notifierState = ref.watch(accountNotifierProvider);
    final isLoading = notifierState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Añadir cuenta bancaria',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            Text(
              '¿En qué banco?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _BankGrid(
              selected: _selectedBank,
              onSelected: _onBankSelected,
              c: c,
              cs: cs,
            ),
            const SizedBox(height: 24),
            Text(
              'Nombre de la cuenta',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration(
                hint: 'Ej: Mi cuenta Popular',
                c: c,
                cs: cs,
              ),
              style: GoogleFonts.inter(fontSize: 14),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Escribe un nombre para identificar la cuenta';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Saldo actual',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _balanceCtrl,
              decoration: _inputDecoration(
                hint: '0',
                prefix: 'RD\$ ',
                helper: 'Puedes ajustarlo después',
                c: c,
                cs: cs,
              ),
              style: GoogleFonts.inter(fontSize: 14),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BDB),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Añadir cuenta',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    String? prefix,
    String? helper,
    required FinPaColors c,
    required ColorScheme cs,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      helperText: helper,
      helperStyle: GoogleFonts.inter(fontSize: 12, color: c.muted),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF3B5BDB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.expense),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c.expense, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bank Grid
// ─────────────────────────────────────────────────────────────────────────────

class _BankGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final FinPaColors c;
  final ColorScheme cs;

  const _BankGrid({
    required this.selected,
    required this.onSelected,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final banks = AccountsRepository.dominicanBanks;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: banks.length,
      itemBuilder: (context, index) {
        final bank = banks[index];
        final name = bank['name']!;
        final isSelected = selected == name;

        return GestureDetector(
          onTap: () => onSelected(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B5BDB).withOpacity(0.1)
                  : cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B5BDB)
                    : c.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(bank['emoji']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF3B5BDB)
                        : cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
