import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';

class CurrencySelectorScreen extends ConsumerWidget {
  const CurrencySelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final cs = theme.colorScheme;
    final currencyState = ref.watch(currencyNotifierProvider);
    final current = currencyState.baseCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('settings.main_currency')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              ref.tr('settings.select_currency').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.muted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...AppCurrency.values.map((currency) {
            final isSelected = currency == current;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2F7155) : c.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Text(
                  currency.flag,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(
                  ref.tr(currency.labelKey),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${currency.code} (${currency.symbol})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: c.muted,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2F7155))
                    : null,
                onTap: () async {
                  try {
                    await ref
                        .read(currencyNotifierProvider.notifier)
                        .setBaseCurrency(currency);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Currency changed to ${currency.code}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error changing currency: $e'),
                          backgroundColor: c.expense,
                        ),
                      );
                    }
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2F7155).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2F7155).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 20, color: Color(0xFF2F7155)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ref.tr('settings.currency_desc'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF2F7155),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
