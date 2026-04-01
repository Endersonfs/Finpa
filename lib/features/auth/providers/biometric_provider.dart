// NOTE: Platform configuration required before use:
//   Android — add to AndroidManifest.xml (inside <manifest>):
//     <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
//   iOS — add to Info.plist:
//     <key>NSFaceIDUsageDescription</key>
//     <string>Usa Face ID para acceder a Finpa de forma segura</string>

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/theme_provider.dart';

// ─────────────────────────────────────────────
//  Constantes
// ─────────────────────────────────────────────
const _kBiometricEnabled = 'biometric_enabled';

// ─────────────────────────────────────────────
//  Estado
// ─────────────────────────────────────────────
class BiometricState {
  final bool isAvailable;
  final bool isEnabled;
  final List<BiometricType> availableTypes;

  const BiometricState({
    required this.isAvailable,
    required this.isEnabled,
    required this.availableTypes,
  });

  BiometricState copyWith({
    bool? isAvailable,
    bool? isEnabled,
    List<BiometricType>? availableTypes,
  }) =>
      BiometricState(
        isAvailable: isAvailable ?? this.isAvailable,
        isEnabled: isEnabled ?? this.isEnabled,
        availableTypes: availableTypes ?? this.availableTypes,
      );

  /// True cuando el dispositivo tiene al menos Face ID disponible.
  bool get hasFaceId => availableTypes.contains(BiometricType.face);

  /// True cuando el dispositivo tiene al menos huella disponible.
  bool get hasFingerprint =>
      availableTypes.contains(BiometricType.fingerprint) ||
      availableTypes.contains(BiometricType.strong);
}

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class BiometricNotifier extends Notifier<BiometricState> {
  final _auth = LocalAuthentication();
  late SharedPreferences _prefs;

  @override
  BiometricState build() {
    _prefs = ref.read(sharedPrefsProvider);
    _init();
    return const BiometricState(
      isAvailable: false,
      isEnabled: false,
      availableTypes: [],
    );
  }

  Future<void> _init() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      List<BiometricType> types = [];
      if (canCheck && isSupported) {
        types = await _auth.getAvailableBiometrics();
      }

      // Solo disponible si hay biometrías enroladas en el dispositivo
      final isAvailable = types.isNotEmpty;

      final isEnabled = _prefs.getBool(_kBiometricEnabled) ?? false;

      state = BiometricState(
        isAvailable: isAvailable,
        isEnabled: isAvailable && isEnabled,
        availableTypes: types,
      );
    } catch (_) {
      state = const BiometricState(
        isAvailable: false,
        isEnabled: false,
        availableTypes: [],
      );
    }
  }

  /// Activa o desactiva la autenticación biométrica.
  Future<void> enableBiometric(bool value) async {
    if (!state.isAvailable) return;
    await _prefs.setBool(_kBiometricEnabled, value);
    state = state.copyWith(isEnabled: value);
  }

  /// Lanza el prompt biométrico nativo y retorna true si el usuario se autenticó.
  /// Lanza [BiometricException] si no hay biometrías enroladas.
  Future<bool> authenticate() async {
    if (!state.isAvailable) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Usa tu huella o Face ID para acceder a Finpa',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        throw BiometricNotEnrolledException();
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────
//  Excepciones
// ─────────────────────────────────────────────
class BiometricNotEnrolledException implements Exception {}

// ─────────────────────────────────────────────
//  Provider público
// ─────────────────────────────────────────────
final biometricProvider =
    NotifierProvider<BiometricNotifier, BiometricState>(
  BiometricNotifier.new,
);
