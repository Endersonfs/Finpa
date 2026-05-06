import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/biometric_provider.dart';
import '../providers/session_provider.dart';
import '../../../core/providers/language_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passCtrl = TextEditingController();
  bool _showPasswordField = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Autenticación biométrica ───────────────

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final success =
          await ref.read(biometricProvider.notifier).authenticate();
      if (!mounted) return;
      if (success) {
        ref.read(sessionProvider.notifier).unlock();
        context.go('/dashboard');
      } else {
        setState(() =>
            _errorMessage = 'Could not verify identity. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Autenticación con contraseña ──────────

  Future<void> _authenticateWithPassword() async {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';
    if (email.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMessage = ref.tr('auth.password_required'));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      ref.read(sessionProvider.notifier).unlock();
      context.go('/dashboard');
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _errorMessage = ref.tr('common.error'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Cerrar sesión ─────────────────────────

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    ref.read(sessionProvider.notifier).unlock();
    context.go('/auth/login');
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final biometric = ref.watch(biometricProvider);

    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        (user?.userMetadata?['full_name'] as String?)?.trim() ??
        (user?.userMetadata?['name'] as String?)?.trim() ??
        user?.email ??
        '';

    // Ícono biométrico dependiendo del tipo disponible
    final biometricIcon = biometric.hasFaceId
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ──────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F7155).withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'FinPa',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ref.tr('auth.session_locked'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.muted,
                ),
              ),
              const SizedBox(height: 8),

              // ── Email del usuario ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141928)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E2840)
                        : const Color(0xFFC7D2FE),
                  ),
                ),
                child: Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // ── Mensaje de error ───────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A0A0A)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF5C1A1A)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: c.expense,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: c.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Campo de contraseña (si se elige esa opción) ──
              if (_showPasswordField) ...[
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _authenticateWithPassword(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: ref.tr('auth.password'),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: c.muted,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: c.muted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: c.muted,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _authenticateWithPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7155),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                            ref.tr('common.confirm'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Botón biométrico ───────────────────────
              if (biometric.isEnabled && biometric.isAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _authenticateWithBiometrics,
                    icon: Icon(biometricIcon, size: 22),
                    label: Text(
                      'Use Biometrics',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7155),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Opción contraseña ──────────────────────
              if (!_showPasswordField)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _showPasswordField = true;
                              _errorMessage = null;
                            });
                          },
                    icon: Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFFE8EEFF)
                          : const Color(0xFF2F7155),
                    ),
                    label: Text(
                      ref.tr('auth.login_with_password'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFE8EEFF)
                            : const Color(0xFF2F7155),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const Spacer(flex: 2),

              // ── Cerrar sesión ──────────────────────────
              TextButton(
                onPressed: _isLoading ? null : _signOut,
                child: Text(
                  ref.tr('settings.logout'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.expense,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
