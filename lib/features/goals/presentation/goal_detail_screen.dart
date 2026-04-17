import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../domain/goal_model.dart';
import '../providers/goals_provider.dart';
import '../../accounts/domain/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _f(double v) => CurrencyFormatter.formatCompact(v);

void _showAmountDetail(BuildContext context, String label, double amount) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyFormatter.formatRD(amount),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2F7155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monto exacto',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  GoalDetailScreen
// ─────────────────────────────────────────────────────────────────────────────
class GoalDetailScreen extends ConsumerWidget {
  final String id;

  const GoalDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary =
        isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (goals) {
        final goalOrNull = goals.cast<SavingGoal?>().firstWhere(
              (g) => g?.id == id,
              orElse: () => null,
            );

        if (goalOrNull == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Meta no encontrada')),
          );
        }

        final goal = goalOrNull;

        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Text(goal.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(goal.title),
            actions: const [SizedBox(width: 8)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Header ──────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(goal.emoji,
                          style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 8),
                      Text(
                        goal.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (goal.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.income.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '¡Meta completada! 🎉',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.income,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: goal.progressColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(goal.progress * 100).round()}% completado',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: goal.progressColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Progress bar ────────────────────────────────────────
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: FractionallySizedBox(
                    widthFactor: goal.progress.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goal.progressColor.withValues(alpha: 0.7),
                            goal.progressColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Amounts row ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _AmountColumn(
                        label: 'Ahorrado',
                        amount: goal.currentAmount,
                        color: c.income,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _AmountColumn(
                        label: 'Meta',
                        amount: goal.targetAmount,
                        color: textPrimary,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _AmountColumn(
                        label: 'Restante',
                        amount: goal.remaining,
                        color: c.expense,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Deadline info ───────────────────────────────────────
                if (goal.deadline != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141928)
                          : const Color(0xFFF0F2F8),
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFF2F7155),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${goal.monthsRemaining} ${goal.monthsRemaining == 1 ? 'mes restante' : 'meses restantes'} · Ahorrar ${_f(goal.requiredMonthlySaving)}/mes',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Add savings button ──────────────────────────────────
                if (!goal.isCompleted) ...[
                  ElevatedButton(
                    onPressed: () =>
                        _showDepositSheet(context, ref, goal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7155),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Agregar ahorro',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _LinkAccountBanner(),
                ],

                const SizedBox(height: 16),

                // ── Delete button ───────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () =>
                        _confirmDelete(context, ref, goal),
                    child: Text(
                      'Eliminar meta',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.expense,
                      ),
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

  void _showDepositSheet(
      BuildContext context, WidgetRef ref, SavingGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DepositSheet(goal: goal, ref: ref),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SavingGoal goal) async {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text(
            '¿Deseas eliminar la meta "${goal.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: c.expense),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(goalNotifierProvider.notifier).remove(goal.id);
      if (context.mounted) context.go('/goals');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _AmountColumn
// ─────────────────────────────────────────────────────────────────────────────
class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: GestureDetector(
            onTap: () => _showAmountDetail(context, label, amount),
            child: Text(
              _f(amount),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _LinkAccountBanner  —  "Activa el dinero real"
// ─────────────────────────────────────────────────────────────────────────────
class _LinkAccountBanner extends StatelessWidget {
  const _LinkAccountBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/accounts'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF141928)
              : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF2F7155).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                size: 16, color: Color(0xFF2F7155)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Activa el dinero real',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2F7155),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                size: 14, color: Color(0xFF2F7155)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DepositSheet
// ─────────────────────────────────────────────────────────────────────────────
class _DepositSheet extends StatefulWidget {
  final SavingGoal goal;
  final WidgetRef ref;

  const _DepositSheet({required this.goal, required this.ref});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _controller = TextEditingController();
  String _amountText = '';
  String? _selectedAccountId;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _amountText.isNotEmpty &&
      double.tryParse(_amountText.replaceAll(',', '.')) != null;

  Future<void> _confirm() async {
    final amount = double.parse(_amountText.replaceAll(',', '.'));
    setState(() => _isSaving = true);
    try {
      await widget.ref.read(goalNotifierProvider.notifier).deposit(
            widget.goal.id,
            amount,
            accountId: _selectedAccountId,
          );
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    final accountsAsync = widget.ref.watch(accountsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar ahorro',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _amountText = v),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            autofocus: true,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: 'RD\$ ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
              hintText: '0',
              hintStyle: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: c.muted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Selector de cuenta
          Text(
            '¿De qué cuenta sale el dinero?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 10),
          accountsAsync.when(
            data: (accounts) {
              final spendable = accounts.where((a) => a.type.isSpendable).toList();
              if (spendable.isEmpty) return const SizedBox.shrink();
              
              _selectedAccountId ??= spendable.firstWhere((a) => a.isDefault, orElse: () => spendable.first).id;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAccountId,
                    dropdownColor: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                    items: spendable.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Text(a.type.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _f(a.balance),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.income,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error al cargar cuentas'),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_isValid && !_isSaving) ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F7155),
              disabledBackgroundColor:
                  const Color(0xFF2F7155).withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirmar ahorro',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

