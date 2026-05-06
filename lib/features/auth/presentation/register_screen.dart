import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../../../core/providers/language_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  int _strength = -1; // -1: sin valor, 0: débil, 1: media, 2: fuerte

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() {
      setState(() => _strength = _computeStrength(_passCtrl.text));
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Fortaleza de contraseña ────────────────

  static int _computeStrength(String p) {
    if (p.isEmpty) return -1;
    if (p.length < 6) return 0;
    final hasUpper = p.contains(RegExp(r'[A-Z]'));
    final hasNumber = p.contains(RegExp(r'\d'));
    final hasSpecial = p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    if (p.length >= 8 && hasUpper && (hasNumber || hasSpecial)) return 2;
    return 1;
  }

  // ── Acciones ───────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError('You must accept terms and conditions'); // Should be localized if needed
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            fullName: _nameCtrl.text.trim(),
          );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(ref.tr('common.error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ── Validadores ────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return ref.tr('auth.login'); // reused or add key
    if (v.trim().length < 2) return 'Name too short';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return ref.tr('auth.email');
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
      return ref.tr('auth.invalid_email');
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return ref.tr('auth.password_required');
    if (v.length < 6) return ref.tr('auth.password_min_length');
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return ref.tr('auth.password_required');
    if (v != _passCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  ref.tr('auth.register'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1F36),
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join and take control of your finances',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 28),

                // Nombre completo
                TextFormField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: _validateName,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'John Doe',
                    prefixIcon:
                        Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: ref.tr('auth.email'),
                    hintText: 'tu@email.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: ref.tr('auth.password'),
                    hintText: '••••••••',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),

                // Indicador de fortaleza
                if (_strength >= 0) ...[
                  const SizedBox(height: 10),
                  _StrengthBar(strength: _strength),
                ],
                const SizedBox(height: 14),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    hintText: '••••••••',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF9CA3AF),
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Términos y condiciones
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: const Color(0xFF2F7155),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) =>
                            setState(() => _acceptedTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'I accept '),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Color(0xFF2F7155),
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // TODO: abrir términos y condiciones
                                },
                            ),
                            const TextSpan(text: ' of FinPa.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Botón crear cuenta
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7155),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            ref.tr('auth.register'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ya tengo cuenta
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${ref.tr('auth.already_have_account')} ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          ref.tr('auth.login'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2F7155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Barra de fortaleza de contraseña (3 segmentos)
// ─────────────────────────────────────────────
class _StrengthBar extends StatelessWidget {
  final int strength; // 0=débil, 1=media, 2=fuerte

  const _StrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final filled = strength + 1; // 1, 2 ó 3 segmentos activos
    final color = switch (strength) {
      0 => const Color(0xFFDC2626),
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF059669),
      _ => const Color(0xFFE2E6F0),
    };

    final label = switch (strength) {
      0 => 'Weak password',
      1 => 'Medium password',
      2 => 'Strong password',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                decoration: BoxDecoration(
                  color: i < filled ? color : const Color(0xFFE2E6F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(strength),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
