---
name: add-feature
description: This skill should be used when the user asks to "crear una feature", "agregar una feature", "nueva feature", "crear módulo", "add feature", or wants to implement a new bounded context following Clean Architecture and DDD in the Finpa Flutter project.
version: 1.0.0
---

# Add Feature — Finpa

Create complete features following Clean Architecture + DDD in three layers: Domain → Data → Presentation.

## Folder Structure to Generate

```
lib/features/{feature}/
  domain/
    entities/
      {entity}.dart
    repositories/
      {entity}_repository.dart        ← interface only
  data/
    models/
      {entity}_model.dart             ← fromJson/toJson + toEntity()
    datasources/
      {entity}_remote_datasource.dart ← Supabase calls
    repositories/
      {entity}_repository_impl.dart   ← implements interface
  presentation/
    providers/
      {entity}_provider.dart          ← Riverpod FutureProvider / StateProvider
    screens/
      {entity}_screen.dart
    widgets/
      (reusable widgets for this feature)
```

## Step-by-Step Process

### Step 1 — Domain Entity

Create a pure Dart class, no external dependencies:

```dart
// lib/features/{feature}/domain/entities/{entity}.dart
class {Entity} {
  final String id;
  final String userId;
  // ... other fields

  const {Entity}({
    required this.id,
    required this.userId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is {Entity} && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### Step 2 — Repository Interface

Define the contract in Domain, no implementation:

```dart
// lib/features/{feature}/domain/repositories/{entity}_repository.dart
abstract class {Entity}Repository {
  Future<List<{Entity}>> getAll();
  Future<{Entity}> getById(String id);
  Future<void> create({Entity} entity);
  Future<void> update({Entity} entity);
  Future<void> delete(String id);
}
```

### Step 3 — Data Model

Extends or wraps the entity, adds JSON serialization:

```dart
// lib/features/{feature}/data/models/{entity}_model.dart
class {Entity}Model {
  final String id;
  final String userId;

  const {Entity}Model({required this.id, required this.userId});

  factory {Entity}Model.fromJson(Map<String, dynamic> json) => {Entity}Model(
    id:     json['id'] as String,
    userId: json['user_id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id':      id,
    'user_id': userId,
  };

  {Entity} toEntity() => {Entity}(id: id, userId: userId);

  factory {Entity}Model.fromEntity({Entity} e) =>
      {Entity}Model(id: e.id, userId: e.userId);
}
```

### Step 4 — Remote DataSource

Calls Supabase, returns models:

```dart
// lib/features/{feature}/data/datasources/{entity}_remote_datasource.dart
class {Entity}RemoteDataSource {
  final SupabaseClient _client;

  {Entity}RemoteDataSource(this._client);

  Future<List<{Entity}Model>> getAll(String userId) async {
    final data = await _client
        .from('{table_name}')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => {Entity}Model.fromJson(e)).toList();
  }

  Future<void> create({Entity}Model model) async {
    await _client.from('{table_name}').insert(model.toJson());
  }

  Future<void> delete(String id) async {
    await _client.from('{table_name}').delete().eq('id', id);
  }
}
```

### Step 5 — Repository Implementation

```dart
// lib/features/{feature}/data/repositories/{entity}_repository_impl.dart
class {Entity}RepositoryImpl implements {Entity}Repository {
  final {Entity}RemoteDataSource _remote;

  {Entity}RepositoryImpl(this._remote);

  @override
  Future<List<{Entity}>> getAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final models = await _remote.getAll(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> create({Entity} entity) async {
    await _remote.create({Entity}Model.fromEntity(entity));
  }

  @override
  Future<void> delete(String id) async => _remote.delete(id);
}
```

### Step 6 — Riverpod Providers

```dart
// lib/features/{feature}/presentation/providers/{entity}_provider.dart
final {entity}RepositoryProvider = Provider<{Entity}Repository>((ref) {
  final client = Supabase.instance.client;
  final remote = {Entity}RemoteDataSource(client);
  return {Entity}RepositoryImpl(remote);
});

final {entity}ListProvider = FutureProvider.autoDispose<List<{Entity}>>((ref) {
  return ref.read({entity}RepositoryProvider).getAll();
});
```

### Step 7 — Screen with loading state

```dart
class {Entity}Screen extends ConsumerWidget {
  const {Entity}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch({entity}ListProvider);
    return Scaffold(
      body: listAsync.when(
        loading: () => const _Skeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : _List(items: items),
      ),
    );
  }
}
```

## Naming Conventions

| Element | Pattern | Example |
|---|---|---|
| Entity | PascalCase | `Budget` |
| Model | `{Entity}Model` | `BudgetModel` |
| Repository interface | `{Entity}Repository` | `BudgetRepository` |
| Repository impl | `{Entity}RepositoryImpl` | `BudgetRepositoryImpl` |
| DataSource | `{Entity}RemoteDataSource` | `BudgetRemoteDataSource` |
| Provider | `{entity}ListProvider` | `budgetListProvider` |

## Architecture Rules (never break)

1. Domain never imports from Data or Presentation
2. Repository interface lives in Domain, implementation in Data
3. No equatable — use manual `==` and `hashCode` by `id`
4. No logic in widgets — all state in providers
5. Supabase only accessible from DataSource layer

## Additional Resources

- **`references/supabase-patterns.md`** — RLS policies and table setup patterns
