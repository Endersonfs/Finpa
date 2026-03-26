import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/account_model.dart';
import '../providers/accounts_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Formatter
// ─────────────────────────────────────────────────────────────────────────────

final _fmt =
    NumberFormat.currency(locale: 'es', symbol: 'RD\$', decimalDigits: 0);

String _f(double v) => _fmt.format(v);

// ─────────────────────────────────────────────────────────────────────────────
//  TransferScreen  —  "Mover dinero"
// ─────────────────────────────────────────────────────────────────────────────

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  AccountModel? _from;
  AccountModel? _to;
  final _amountCtrl = TextEditingController();
  double _amount = 0;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() {
      final raw = _amountCtrl.text.replaceAll(',', '.');
      setState(() => _amount = double.tryParse(raw) ?? 0);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _from != null && _to != null && _from!.id != _to!.id && _amount > 0;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final ok = await ref.read(transferNotifierProvider.notifier).transfer(
          fromAccountId: _from!.id,
          toAccountId: _to!.id,
          amount: _amount,
        );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Listo, moviste ${_f(_amount)} ✓',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      final state = ref.read(transferNotifierProvider);
      final msg = state is AsyncError ? state.error.toString() : 'Error al mover el dinero';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              Theme.of(context).extension<FinPaColors>()!.expense,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isLoading = ref.watch(transferNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mover dinero',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => _TransferBody(
          accounts: accounts,
          from: _from,
          to: _to,
          amount: _amount,
          amountCtrl: _amountCtrl,
          canSubmit: _canSubmit,
          isLoading: isLoading,
          onFromChanged: (a) => setState(() => _from = a),
          onToChanged: (a) => setState(() => _to = a),
          onSubmit: _submit,
          c: c,
          cs: cs,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Body
// ─────────────────────────────────────────────────────────────────────────────

class _TransferBody extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? from;
  final AccountModel? to;
  final double amount;
  final TextEditingController amountCtrl;
  final bool canSubmit;
  final bool isLoading;
  final ValueChanged<AccountModel?> onFromChanged;
  final ValueChanged<AccountModel?> onToChanged;
  final VoidCallback onSubmit;
  final FinPaColors c;
  final ColorScheme cs;

  const _TransferBody({
    required this.accounts,
    required this.from,
    required this.to,
    required this.amount,
    required this.amountCtrl,
    required this.canSubmit,
    required this.isLoading,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSubmit,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final spendable = accounts.where((a) => a.type.isSpendable).toList();
    final toDestinations = accounts.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        // ── Origen ────────────────────────────────────────────────────────
        Text(
          '¿De dónde?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _AccountDropdown(
          hint: 'Elige la cuenta origen',
          accounts: spendable,
          selected: from,
          onChanged: onFromChanged,
          c: c,
          cs: cs,
        ),
        const SizedBox(height: 20),

        // ── Destino ───────────────────────────────────────────────────────
        Text(
          '¿A dónde?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _AccountDropdown(
          hint: 'Elige la cuenta destino',
          accounts: toDestinations
              .where((a) => a.id != from?.id)
              .toList(),
          selected: to,
          onChanged: onToChanged,
          c: c,
          cs: cs,
        ),
        const SizedBox(height: 28),

        // ── Monto ─────────────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Text(
                '¿Cuánto quieres mover?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.muted,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: amountCtrl,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: c.muted,
                    ),
                    prefixText: 'RD\$ ',
                    prefixStyle: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: c.muted,
                    ),
                    border: InputBorder.none,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Vista previa animada ───────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _BalancePreview(
            from: from,
            to: to,
            amount: amount,
            c: c,
            cs: cs,
          ),
          crossFadeState: canSubmit
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),

        // ── Progreso de meta si destino=savings ───────────────────────────
        if (to?.type == AccountType.savings && amount > 0) ...[
          const SizedBox(height: 16),
          _SavingsGoalPreview(account: to!, amount: amount, c: c, cs: cs),
        ],

        const SizedBox(height: 28),

        // ── Botón ─────────────────────────────────────────────────────────
        FilledButton(
          onPressed: (canSubmit && !isLoading) ? onSubmit : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3B5BDB),
            foregroundColor: Colors.white,
            disabledBackgroundColor: c.cardBg,
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
                  amount > 0 ? 'Mover ${_f(amount)}' : 'Mover dinero',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Account Dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _AccountDropdown extends StatelessWidget {
  final String hint;
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final ValueChanged<AccountModel?> onChanged;
  final FinPaColors c;
  final ColorScheme cs;

  const _AccountDropdown({
    required this.hint,
    required this.accounts,
    required this.selected,
    required this.onChanged,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountModel>(
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.inter(fontSize: 14, color: c.muted),
          ),
          value: selected,
          onChanged: onChanged,
          items: accounts.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Row(
                children: [
                  Text(a.type.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.name,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    _f(a.balance),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Balance Preview (animada)
// ─────────────────────────────────────────────────────────────────────────────

class _BalancePreview extends StatelessWidget {
  final AccountModel? from;
  final AccountModel? to;
  final double amount;
  final FinPaColors c;
  final ColorScheme cs;

  const _BalancePreview({
    required this.from,
    required this.to,
    required this.amount,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    if (from == null || to == null) return const SizedBox.shrink();

    final fromAfter = from!.balance - amount;
    final toAfter = to!.balance + amount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así quedan los saldos',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          _BalanceRow(
            emoji: from!.type.emoji,
            name: from!.name,
            before: from!.balance,
            after: fromAfter,
            isNegative: true,
            c: c,
            cs: cs,
          ),
          const SizedBox(height: 8),
          _BalanceRow(
            emoji: to!.type.emoji,
            name: to!.name,
            before: to!.balance,
            after: toAfter,
            isNegative: false,
            c: c,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String emoji;
  final String name;
  final double before;
  final double after;
  final bool isNegative;
  final FinPaColors c;
  final ColorScheme cs;

  const _BalanceRow({
    required this.emoji,
    required this.name,
    required this.before,
    required this.after,
    required this.isNegative,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final arrowColor = isNegative ? c.expense : c.income;
    final arrowIcon =
        isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _f(before),
          style: GoogleFonts.inter(fontSize: 12, color: c.muted),
        ),
        const SizedBox(width: 4),
        Icon(arrowIcon, size: 14, color: arrowColor),
        const SizedBox(width: 4),
        Text(
          _f(after),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: after < 0 ? c.expense : cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Savings Goal Preview
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsGoalPreview extends StatelessWidget {
  final AccountModel account;
  final double amount;
  final FinPaColors c;
  final ColorScheme cs;

  const _SavingsGoalPreview({
    required this.account,
    required this.amount,
    required this.c,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final newBalance = account.balance + amount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B5BDB).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF3B5BDB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏺', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B5BDB),
                  ),
                ),
              ),
              Text(
                _f(newBalance),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B5BDB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (newBalance / (newBalance * 2)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF3B5BDB).withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF3B5BDB)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quedaría con ${_f(newBalance)} apartado',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF3B5BDB).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
