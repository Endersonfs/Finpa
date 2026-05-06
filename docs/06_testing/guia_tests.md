# Guía de Tests en Finpa

Stack: `flutter_test` + `mocktail` (sin `mockito`).

---

## Tipos de tests

| Tipo | Qué testea | Carpeta |
|------|-----------|---------|
| Unit test | Una función/clase en aislamiento | `test/unit/` |
| Widget test | Un widget con su árbol de providers | `test/widget/` |
| Integration test | Flujo completo con Supabase real | `integration_test/` |

---

## Estructura de un test unitario

```
test/
  unit/
    repositories/
      transaction_repository_test.dart
    providers/
      theme_provider_test.dart
    utils/
      language_state_test.dart
  widget/
    screens/
      dashboard_screen_test.dart
      add_transaction_screen_test.dart
```

---

## Patrón AAA (Arrange — Act — Assert)

```dart
test('fetchAll retorna solo las transacciones del usuario', () async {
  // ARRANGE — preparar los datos y dependencias
  final userId = 'user-123';
  final model = TransactionModel(
    id: 'tx-1',
    userId: userId,
    amount: 100,
    type: 'income',
    category: 'salary',
    date: '2024-01-15',
    createdAt: DateTime.now().toIso8601String(),
  );
  await HiveService.saveTransaction(model);

  // ACT — ejecutar lo que se testea
  final repo = TransactionRepository(mockClient);
  final result = await repo.fetchAll();

  // ASSERT — verificar el resultado
  expect(result, hasLength(1));
  expect(result.first.id, equals('tx-1'));
  expect(result.first.type, equals(TransactionType.income));
});
```

---

## Mockear con mocktail

```dart
import 'package:mocktail/mocktail.dart';

// 1. Crear el mock
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

// 2. Configurar comportamiento
final mockRepo = MockTransactionRepository();

when(() => mockRepo.fetchAll()).thenAnswer(
  (_) async => [
    Transaction(
      id: 'tx-1',
      userId: 'user-1',
      amount: 150,
      type: TransactionType.income,
      category: 'salary',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    ),
  ],
);

// Simular error
when(() => mockRepo.add(any())).thenThrow(
  Exception('Sin conexión'),
);

// 3. Verificar que se llamó
verify(() => mockRepo.fetchAll()).called(1);
verifyNever(() => mockRepo.delete(any()));
```

---

## Test de widget con Riverpod (ProviderScope)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

testWidgets('DashboardScreen muestra shimmer mientras carga', (tester) async {
  // ARRANGE — override del provider para controlar el estado
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Simular estado de carga
        transactionsProvider.overrideWith(
          (ref) => Stream.fromFuture(
            Future.delayed(const Duration(seconds: 5), () => <Transaction>[]),
          ),
        ),
        // Inyectar SharedPreferences de prueba
        sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.setMockInitialValues({}),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );

  // ACT — hacer pump inicial
  await tester.pump();

  // ASSERT — debe mostrar shimmer (no datos)
  expect(find.byType(TransactionTileShimmer), findsWidgets);
  expect(find.byType(TransactionTile), findsNothing);
});
```

---

## Test de formulario (validación)

```dart
testWidgets('AddTransactionScreen — monto vacío no permite guardar', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...],
      child: const MaterialApp(home: AddTransactionScreen()),
    ),
  );

  // Encontrar y tocar el botón sin completar el formulario
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Debe mostrar error de validación
  expect(find.text('El monto es requerido'), findsOneWidget);
});
```

---

## Test unitario de LanguageState.translate

```dart
test('translate retorna el valor para una clave simple', () {
  final state = LanguageState(
    locale: const Locale('es'),
    translations: {'greeting': 'Hola'},
  );

  expect(state.translate('greeting'), equals('Hola'));
});

test('translate retorna el valor para claves anidadas', () {
  final state = LanguageState(
    locale: const Locale('es'),
    translations: {
      'dashboard': {'balance': 'Saldo total'},
    },
  );

  expect(state.translate('dashboard.balance'), equals('Saldo total'));
});

test('translate retorna la clave si no existe', () {
  final state = LanguageState(
    locale: const Locale('es'),
    translations: {},
  );

  expect(state.translate('key.inexistente'), equals('key.inexistente'));
});
```

---

## Ejecutar tests

```bash
# Todos los tests
flutter test

# Un archivo específico
flutter test test/unit/repositories/transaction_repository_test.dart

# Con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# abrir coverage/html/index.html en el navegador

# Solo tests con nombre específico
flutter test --name "fetchAll retorna"
```

---

## Buenas prácticas

- Cada test es **independiente** — no depende del orden de ejecución
- Limpiar Hive entre tests con `Hive.deleteBoxFromDisk()` en `tearDown`
- No testear implementación, testear **comportamiento**: "cuando X, espero Y"
- Un test = una assertion principal (puede tener secundarias)
- Nombres descriptivos: `'fetchAll retorna transacciones del mes filtradas por usuario'`
