# Finpa - Contexto del Proyecto

## Qué es Finpa
Aplicación móvil financiera personal desarrollada en Flutter.
Plataformas: Android e iOS.

## Arquitectura: Clean Architecture + DDD

### Capas (de adentro hacia afuera)
```
Domain → Data → Presentation
```

1. **Domain** (núcleo, sin dependencias externas)
   - `entities/` — Objetos de negocio puros (extienden `Equatable`)
   - `value_objects/` — Tipos con validación (ej: `Email`, `Amount`)
   - `repositories/` — Interfaces (contratos) que define el dominio
   - `usecases/` — Casos de uso, heredan de `UseCase<Type, Params>`

2. **Data** (implementaciones)
   - `models/` — DTOs que extienden las entidades del dominio
   - `datasources/` — Remote (Dio/API) y Local (SharedPrefs/SecureStorage)
   - `repositories/` — Implementaciones de las interfaces del dominio

3. **Presentation** (UI)
   - `bloc/` — BLoC: `event.dart`, `state.dart`, `bloc.dart`
   - `pages/` — Pantallas completas
   - `widgets/` — Componentes reutilizables

### Estructura de Carpetas
```
lib/
  core/
    errors/           # Failure, AppException
    network/          # DioClient, interceptors
    usecase/          # UseCase base class
    utils/
    theme/
    constants/
    di/               # injection_container.dart
  features/
    {feature}/        # Bounded Context DDD
      data/
      domain/
      presentation/
  app.dart
  main.dart
  injection_container.dart
```

## Reglas de Arquitectura (OBLIGATORIAS)

1. **Domain nunca importa de Data ni Presentation**
2. **Repositories en Domain son interfaces**, las implementaciones van en Data
3. **Errores con Either<Failure, T>** de `dartz` — nunca lanzar excepciones en repositorios
4. **Entities usan Equatable** para comparación por valor
5. **Value Objects validan en constructor** — retornan `Either<Failure, ValueObject>`
6. **BLoC maneja TODO el estado** — no lógica en widgets
7. **Inyección con GetIt + Injectable** — no instanciar clases directamente en widgets
8. **Modelos tienen `fromJson`/`toJson`** y método `toEntity()`

## Convenciones de Nombres

- Entidades: `User`, `Transaction`, `Account`
- Modelos: `UserModel`, `TransactionModel`
- Repositorios (interfaz): `UserRepository`
- Repositorios (impl): `UserRepositoryImpl`
- DataSources: `UserRemoteDataSource`, `UserLocalDataSource`
- UseCases: `GetUserUseCase`, `CreateTransactionUseCase`
- BLoC: `AuthBloc`, `AuthEvent`, `AuthState`
- Value Objects: `Email`, `Password`, `MoneyAmount`

## Estado del Proyecto
- Inicio: Clean Architecture + DDD setup
- Siguiente: Definir bounded contexts (features) con el usuario

## Stack Técnico
- Flutter 3.38.1 / Dart 3.10
- State: flutter_bloc 8.x
- DI: get_it + injectable
- FP: dartz (Either/Option)
- HTTP: dio
- Routing: go_router
- Local: shared_preferences + flutter_secure_storage
- Code gen: freezed + json_serializable + build_runner
- Tests: bloc_test + mocktail

## Sub-agentes disponibles
- `flutter-architect` — decisiones de arquitectura, estructura de features
- `domain-modeler` — entidades DDD, value objects, aggregates
- `flutter-ui` — widgets, páginas, BLoC
- `test-writer` — tests unitarios, de widgets, integración
