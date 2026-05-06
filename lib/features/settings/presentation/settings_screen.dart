import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<FinPaColors>()!;
    final currencyState = ref.watch(currencyNotifierProvider);
    final langState = ref.watch(languageNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('settings.title')),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          _SectionTitle(title: ref.tr('settings.profile')),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: ref.tr('settings.profile'),
            subtitle: ref.tr('settings.manage_profile'),
            onTap: () => context.push('/profile'),
          ),
          
          const SizedBox(height: 24),
          _SectionTitle(title: ref.tr('settings.preferences')),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: ref.tr('settings.language'),
            subtitle: langState.locale.languageCode == 'es' ? 'Español' : 'English',
            trailing: Text(
              langState.locale.languageCode.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2F7155),
              ),
            ),
            onTap: () => _showLanguagePicker(context, ref, langState.locale.languageCode),
          ),
          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: ref.tr('settings.main_currency'),
            subtitle: ref.tr('settings.currency_desc'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2F7155).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currencyState.baseCurrency.flag} ${currencyState.baseCurrency.code}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2F7155),
                ),
              ),
            ),
            onTap: () => _showCurrencyPicker(context, ref, currencyState.baseCurrency),
          ),
          _SettingsTile(
            icon: Icons.palette_rounded,
            title: ref.tr('settings.appearance'),
            subtitle: ref.tr('settings.appearance_desc'),
            onTap: () => context.push('/settings/appearance'),
          ),

          const SizedBox(height: 24),
          _SectionTitle(title: ref.tr('settings.security_data')),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: ref.tr('settings.notifications'),
            subtitle: ref.tr('settings.notifications_desc'),
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: ref.tr('settings.security'),
            subtitle: ref.tr('settings.security_desc'),
            onTap: () => context.push('/settings/security'),
          ),
          
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${ref.tr('common.version')} 1.0.0 (Build 1)',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                ref.tr('settings.select_language'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Español', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: current == 'es' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2F7155)) : null,
              onTap: () {
                ref.read(languageNotifierProvider.notifier).setLocale('es');
                Navigator.pop(context);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: current == 'en' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2F7155)) : null,
              onTap: () {
                ref.read(languageNotifierProvider.notifier).setLocale('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, AppCurrency current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                ref.tr('settings.select_currency'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...AppCurrency.values.map((currency) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
              title: Text(
                ref.tr(currency.labelKey),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              trailing: currency == current
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2F7155))
                  : null,
              onTap: () {
                ref.read(currencyNotifierProvider.notifier).setBaseCurrency(currency);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${ref.tr('settings.main_currency')}: ${ref.tr(currency.labelKey)}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E2840) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4B5563)),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: c.muted,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
