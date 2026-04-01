import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/theme_provider.dart';

// ─────────────────────────────────────────────
//  Constantes de claves SharedPreferences
// ─────────────────────────────────────────────
const _kInactivityTimeout  = 'session_timeout_minutes';
const _kBgTimeout          = 'session_bg_timeout_minutes';
const _kTimeoutEnabled     = 'session_timeout_enabled';

const _kDefaultInactivity  = 5;
const _kDefaultBgTimeout   = 2;

// ─────────────────────────────────────────────
//  Estado de sesión
// ─────────────────────────────────────────────
class SessionState {
  final bool isLocked;
  final DateTime lastActivityAt;
  final int inactivityTimeoutMinutes;
  final int backgroundTimeoutMinutes;
  final bool isSessionTimeoutEnabled;

  const SessionState({
    required this.isLocked,
    required this.lastActivityAt,
    required this.inactivityTimeoutMinutes,
    required this.backgroundTimeoutMinutes,
    required this.isSessionTimeoutEnabled,
  });

  SessionState copyWith({
    bool? isLocked,
    DateTime? lastActivityAt,
    int? inactivityTimeoutMinutes,
    int? backgroundTimeoutMinutes,
    bool? isSessionTimeoutEnabled,
  }) =>
      SessionState(
        isLocked: isLocked ?? this.isLocked,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        inactivityTimeoutMinutes:
            inactivityTimeoutMinutes ?? this.inactivityTimeoutMinutes,
        backgroundTimeoutMinutes:
            backgroundTimeoutMinutes ?? this.backgroundTimeoutMinutes,
        isSessionTimeoutEnabled:
            isSessionTimeoutEnabled ?? this.isSessionTimeoutEnabled,
      );
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class SessionNotifier extends Notifier<SessionState> {
  late SharedPreferences _prefs;

  @override
  SessionState build() {
    _prefs = ref.read(sharedPrefsProvider);
    // Si la biometría está activa, la app debe arrancar bloqueada
    final biometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
    return SessionState(
      isLocked: biometricEnabled,
      lastActivityAt: DateTime.now(),
      inactivityTimeoutMinutes:
          _prefs.getInt(_kInactivityTimeout) ?? _kDefaultInactivity,
      backgroundTimeoutMinutes:
          _prefs.getInt(_kBgTimeout) ?? _kDefaultBgTimeout,
      isSessionTimeoutEnabled:
          _prefs.getBool(_kTimeoutEnabled) ?? true,
    );
  }

  /// Restablece el timer de inactividad.
  void updateActivity() {
    if (state.isLocked) return;
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  /// Bloquea la sesión — muestra la pantalla de lock.
  void lock() {
    state = state.copyWith(isLocked: true);
  }

  /// Desbloquea la sesión tras autenticación exitosa.
  void unlock() {
    state = state.copyWith(
      isLocked: false,
      lastActivityAt: DateTime.now(),
    );
  }

  /// Persiste y aplica el nuevo tiempo de inactividad.
  Future<void> setInactivityTimeout(int minutes) async {
    await _prefs.setInt(_kInactivityTimeout, minutes);
    state = state.copyWith(inactivityTimeoutMinutes: minutes);
  }

  /// Persiste y aplica el nuevo tiempo en segundo plano.
  Future<void> setBackgroundTimeout(int minutes) async {
    await _prefs.setInt(_kBgTimeout, minutes);
    state = state.copyWith(backgroundTimeoutMinutes: minutes);
  }

  /// Activa o desactiva el cierre automático de sesión.
  Future<void> setSessionTimeoutEnabled(bool value) async {
    await _prefs.setBool(_kTimeoutEnabled, value);
    state = state.copyWith(isSessionTimeoutEnabled: value);
  }
}

// ─────────────────────────────────────────────
//  Provider público
// ─────────────────────────────────────────────
final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
