import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/account_model.dart';
import '../../../goals/domain/goal_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AccountMiniCard  —  100×80px, para el scroll horizontal del Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class AccountMiniCard extends StatelessWidget {
  final AccountModel account;

  /// Meta vinculada a la cuenta (solo aplica si type == savings).
  /// Cuando se provee, se muestra la barra de progreso inferior.
  final SavingGoal? linkedGoal;

  const AccountMiniCard({
    super.key,
    required this.account,
    this.linkedGoal,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final balanceColor = _balanceColor(account.type);
    final progress = _goalProgress();

    return GestureDetector(
      onTap: () => context.push('/accounts'),
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1320) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2840) : const Color(0xFFE2E6F0),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Contenido principal ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: emoji + nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        account.type.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          account.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: c.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Saldo
                  Text(
                    CurrencyFormatter.format(account.balance, currency: account.currency),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: balanceColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // ── Barra de progreso de meta (solo savings) ─────────────────
            if (account.type == AccountType.savings)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ProgressBar(progress: progress),
              ),
          ],
        ),
      ),
    );
  }

  Color _balanceColor(AccountType type) {
    switch (type) {
      case AccountType.credit:
        return const Color(0xFFDC2626);
      case AccountType.savings:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2F7155); // primary — isSpendable
    }
  }

  /// Progreso hacia la meta: 0.0–1.0.
  /// Si no hay meta vinculada o target=0, devuelve 0.
  double _goalProgress() {
    final goal = linkedGoal;
    if (goal == null || goal.targetAmount <= 0) return 0;
    return (account.balance / goal.targetAmount).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Barra de progreso de 2px pegada al fondo
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final filledWidth = totalWidth * progress.clamp(0.0, 1.0);

          return Stack(
            children: [
              // Track
              Container(
                width: totalWidth,
                height: 4,
                color: isDark
                    ? const Color(0xFF7C3AED).withOpacity(0.2)
                    : const Color(0xFF7C3AED).withOpacity(0.12),
              ),
              // Fill
              Container(
                width: filledWidth,
                height: 4,
                color: const Color(0xFF7C3AED),
              ),
            ],
          );
        },
      ),
    );
  }
}
