import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/currencies.dart';
import '../utils/currency_formatter.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class CompactAmountText extends ConsumerWidget {
  final double amount;
  final AppCurrency? currency;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool useFullOnTap;

  const CompactAmountText({
    super.key,
    required this.amount,
    this.currency,
    this.style,
    this.textAlign,
    this.useFullOnTap = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatted = CurrencyFormatter.formatCompact(amount, currency: currency);

    Widget text = Text(
      formatted,
      style: style,
      textAlign: textAlign,
    );

    if (!useFullOnTap) return text;

    return GestureDetector(
      onTap: () => _showFullAmount(context, ref),
      child: text,
    );
  }

  void _showFullAmount(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          ref.tr('goals.exact_amount'),
          style: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.w600, 
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatDecimal(amount, currency: currency),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2F7155),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${ref.tr('accounts.currency')}: ${currency != null ? ref.tr(currency!.labelKey) : 'N/A'} (${currency?.code ?? 'N/A'})',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: c.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.tr('common.close'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
