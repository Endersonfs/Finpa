import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/goal_model.dart';
import '../providers/goals_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────
const _emojis = [
  '✈️',
  '💻',
  '🏠',
  '🚗',
  '💍',
  '📚',
  '🎓',
  '⚕️',
  '🎮',
  '🌴',
  '🐾',
  '➕',
];

final _fmt =
    NumberFormat.currency(locale: 'es', symbol: 'RD\$', decimalDigits: 0);

String _f(double v) => _fmt.format(v);

// ─────────────────────────────────────────────────────────────────────────────
//  AddGoalScreen
// ─────────────────────────────────────────────────────────────────────────────
class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  String _emoji = '✈️';
  String _title = '';
  String _amountText = '';
  DateTime? _deadline;
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _title.trim().isNotEmpty &&
      _amountText.isNotEmpty &&
      double.tryParse(_amountText.replaceAll(',', '.')) != null;

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final target =
        double.parse(_amountText.replaceAll(',', '.'));
    final goal = SavingGoal(
      id: '',
      userId: Supabase.instance.client.auth.currentUser!.id,
      title: _title.trim(),
      emoji: _emoji,
      targetAmount: target,
      currentAmount: 0,
      deadline: _deadline,
      createdAt: DateTime.now(),
    );
    setState(() => _isSaving = true);
    try {
      await ref.read(goalNotifierProvider.notifier).add(goal);
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
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);
    final textSecondary =
        isDark ? const Color(0xFF8892B0) : const Color(0xFF6B7280);

    final targetValue =
        double.tryParse(_amountText.replaceAll(',', '.'));
    final hasTarget = targetValue != null && targetValue > 0;

    int months = 12;
    if (_deadline != null && hasTarget) {
      final now = DateTime.now();
      months = max(
        1,
        (_deadline!.year - now.year) * 12 +
            (_deadline!.month - now.month),
      );
    }
    final monthly = hasTarget ? targetValue / months : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Nueva meta'),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Emoji grid ────────────────────────────────────────────────
            Text(
              'Elige un ícono',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark
                              ? const Color(0xFF0F1320)
                              : const Color(0xFFEEF2FF))
                          : c.cardBg,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF3B5BDB)
                            : c.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(e,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Title field ───────────────────────────────────────────────
            Text(
              'Nombre de la meta',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              onChanged: (v) => setState(() => _title = v),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Viaje a Europa, iPhone nuevo',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: c.muted),
              ),
            ),

            const SizedBox(height: 24),

            // ── Amount field ──────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    'META DE AHORRO',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: c.muted,
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
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _amountController,
                          onChanged: (v) =>
                              setState(() => _amountText = v),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]')),
                          ],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
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
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Deadline picker ───────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141928)
                    : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded,
                      size: 18,
                      color: const Color(0xFF3B5BDB)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'Sin fecha límite'
                          : 'Hasta ${DateFormat('dd/MM/yyyy').format(_deadline!)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _deadline == null
                            ? c.muted
                            : textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _deadline == null ? _pickDate : () {
                          setState(() => _deadline = null);
                        },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _deadline == null ? 'Cambiar' : 'Quitar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B5BDB),
                      ),
                    ),
                  ),
                  if (_deadline == null)
                    const SizedBox.shrink()
                  else
                    TextButton(
                      onPressed: _pickDate,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cambiar',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3B5BDB),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── FinPa AI banner ───────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: hasTarget
                  ? Container(
                      key: const ValueKey('ai-banner'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0A1F0F)
                            : const Color(0xFFECFDF5),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF14532D)
                              : const Color(0xFFA7F3D0),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 18,
                            color: c.income,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Ahorra ',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: c.income,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${_f(monthly)}/mes',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c.income,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' para alcanzar esta meta en $months ${months == 1 ? 'mes' : 'meses'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: c.income,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('ai-empty')),
            ),

            const SizedBox(height: 28),

            // ── Save button ───────────────────────────────────────────────
            ElevatedButton(
              onPressed: (_isValid && !_isSaving) ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BDB),
                disabledBackgroundColor:
                    const Color(0xFF3B5BDB).withValues(alpha: 0.4),
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
                      'Crear meta',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
