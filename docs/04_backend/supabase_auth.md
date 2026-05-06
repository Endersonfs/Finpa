# Supabase Auth en Finpa

---

## Métodos disponibles

```dart
// lib/features/auth/data/auth_repository.dart

// Login con email y contraseña
final response = await repo.signIn(email: email, password: password);

// Registro
final response = await repo.signUp(
  email: email,
  password: password,
  fullName: fullName,  // se guarda en user_metadata
);

// OAuth con Google (abre navegador)
await repo.signInWithGoogle();
// Requiere configurar redirect: 'io.supabase.finpa://login-callback/'

// Cerrar sesión
await repo.signOut();

// Recuperar contraseña (envía email)
await repo.resetPassword(email);

// Usuario actual (sync, no async)
final user = repo.getCurrentUser(); // null si no hay sesión
```

---

## Escuchar cambios de sesión

```dart
// StreamProvider — emite en cada cambio de auth
final authStateProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

// Uso en widget
ref.listen(authStateProvider, (_, next) {
  next.whenData((authState) {
    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        context.go('/dashboard');
      case AuthChangeEvent.signedOut:
        context.go('/auth/login');
      default:
        break;
    }
  });
});
```

---

## Biometría — LockScreen

El flujo de lock de sesión es independiente del auth de Supabase:

```dart
// sessionProvider rastrea si la pantalla está bloqueada
// Se bloquea automáticamente después de X segundos en background

// Para desbloquear (en LockScreen)
await ref.read(biometricProvider.notifier).authenticate();

// Si falla, el usuario puede ingresar su PIN / contraseña
```

---

## Acceder al usuario actual

```dart
// Desde cualquier repositorio
final userId = Supabase.instance.client.auth.currentUser!.id;

// Desde un provider
final user = Supabase.instance.client.auth.currentUser;
if (user == null) throw Exception('No hay sesión activa');

// Metadatos del usuario (nombre guardado al registrarse)
final fullName = user.userMetadata?['full_name'] as String? ?? '';
```

---

## Configuración necesaria en Supabase Dashboard

Para que OAuth con Google funcione:

1. **Authentication > Providers > Google**: activar y agregar Client ID + Secret
2. **Authentication > URL Configuration**: agregar `io.supabase.finpa://login-callback/` a Redirect URLs

Para Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.finpa" android:host="login-callback" />
</intent-filter>
```

---

## Variables de entorno requeridas (`.env`)

```
SUPABASE_URL=https://xxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ANTHROPIC_API_KEY=sk-ant-...
```

Si `SUPABASE_URL` o `SUPABASE_ANON_KEY` están vacías, la app funciona sin backend (modo offline puro). Si `ANTHROPIC_API_KEY` está vacía, el chat de IA muestra respuestas de fallback.

---

## Manejo de errores de Auth

Supabase lanza `AuthException` con mensajes específicos:

```dart
try {
  await repo.signIn(email: email, password: password);
} on AuthException catch (e) {
  switch (e.message) {
    case 'Invalid login credentials':
      // credenciales incorrectas
    case 'Email not confirmed':
      // email sin verificar
    default:
      // error genérico
  }
}
```

Los mensajes de `AuthException` vienen en inglés desde Supabase. Hay que mapearlos a claves de traducción para mostrar mensajes correctos al usuario.
