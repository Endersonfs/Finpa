import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../ai_chat/data/ai_repository.dart';
import '../domain/budget_model.dart';
import '../providers/budget_provider.dart';

// ── Mapas de categoría ────────────────────────────────────────────────────────

const _kLabel = {
  'food': 'Comida',
  'transport': 'Transporte',
  'entertainment': 'Entretenimiento',
  'services': 'Servicios',
  'health': 'Salud',
  'clothing': 'Ropa',
  'housing': 'Hogar',
  'education': 'Educación',
  'shopping': 'Compras',
  'other': 'Otros',
};

const _kEmoji = {
  'food': '🍔',
  'transport': '🚗',
  'entertainment': '🎬',
  'services': '💡',
  'health': '💊',
  'clothing': '👗',
  'housing': '🏠',
  'education': '📚',
  'shopping': '🛍️',
  'other': '📊',
};

// ── AddBudgetScreen ───────────────────────────────────────────────────────────

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  String _category = 'food';
  String _limitText = '';
  bool _alertAt80 = true;
  bool _isSaving = false;
  String _period = 'Mensual';

  final _limitController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _limitText.isNotEmpty &&
      double.tryParse(_limitText.replaceAll(',', '.')) != null &&
      double.parse(_limitText.replaceAll(',', '.')) > 0;

  Future<void> _save() async {
    final limit = double.parse(_limitText.replaceAll(',', '.'));
    final now = DateTime.now();
    final budget = Budget(
      id: '',
      userId: Supabase.instance.client.auth.currentUser!.id,
      category: _category,
      limitAmount: limit,
      spent: 0,
      month: now.month,
      year: now.year,
      alertAt80: _alertAt80,
    );
    setState(() => _isSaving = true);
    try {
      await ref.read(budgetNotifierProvider.notifier).add(budget);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = Theme.of(context).extension<FinPaColors>()!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo presupuesto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── 1. Selector de categoría ─────────────────────────────────
            Text(
              'Categoría',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  iconEnabledColor: c.muted,
                  dropdownColor: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                  items: _kLabel.entries.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.key,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                              _kEmoji[e.key] ?? '📊',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              e.value,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── 2. Campo límite mensual ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'LÍMITE MENSUAL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'RD\$',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d,.]'),
                          ),
                        ],
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
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2F7155)),
                          ),
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => setState(() => _limitText = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 3. Chips de período ──────────────────────────────────────
            Row(
              children: ['Mensual', 'Semanal', 'Anual'].map((period) {
                final isActive = _period == period;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: period == 'Mensual' ? 0 : 4,
                      right: period == 'Anual' ? 0 : 4,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _period = period),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2F7155)
                              : cs.surface,
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF2F7155)
                                : c.border,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          period,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive ? Colors.white : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── 4. Banner FinPa IA ───────────────────────────────────────
            FutureBuilder<String>(
              future: const AiRepository().generateAutoTip(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return _AiBannerSkeleton(isDark: isDark, border: c.border);
                }
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F1320)
                        : const Color(0xFFEEF2FF),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFC7D2FE),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFF2F7155),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          snap.data!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF3730A3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── 5. Toggle alerta 80% ─────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: const Color(0xFF2F7155),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Alertarme al llegar al 80%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _alertAt80,
                  activeColor: const Color(0xFF2F7155),
                  onChanged: (v) => setState(() => _alertAt80 = v),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── 6. Botón crear presupuesto ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canSave && !_isSaving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F7155),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.border,
                  disabledForegroundColor: c.muted,
                  elevation: 0,
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
                        'Crear presupuesto',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── AI Banner Skeleton ────────────────────────────────────────────────────────

class _AiBannerSkeleton extends StatefulWidget {
  final bool isDark;
  final Color border;

  const _AiBannerSkeleton({required this.isDark, required this.border});

  @override
  State<_AiBannerSkeleton> createState() => _AiBannerSkeletonState();
}

class _AiBannerSkeletonState extends State<_AiBannerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? const Color(0xFF1E2840)
        : const Color(0xFFE2E6F0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _anim.value),
          border: Border.all(color: widget.border),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

