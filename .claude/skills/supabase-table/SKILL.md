---
name: supabase-table
description: This skill should be used when the user asks to "crear tabla en supabase", "crear tabla", "agregar tabla", "configurar supabase", "políticas RLS", "RLS policies", "crear schema", or wants to set up a Supabase table with proper security for the Finpa app.
version: 1.0.0
---

# Supabase Table — Finpa

Generate complete Supabase table setup: SQL schema, RLS policies, and the matching Dart model.

## Standard Table Template

Every Finpa table follows this pattern:

```sql
-- 1. Create table
CREATE TABLE public.{table_name} (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
  -- add columns here
);

-- 2. Enable RLS
ALTER TABLE public.{table_name} ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies (users only see their own data)
CREATE POLICY "Users can view own {table_name}"
  ON public.{table_name} FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own {table_name}"
  ON public.{table_name} FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own {table_name}"
  ON public.{table_name} FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own {table_name}"
  ON public.{table_name} FOR DELETE
  USING (auth.uid() = user_id);

-- 4. Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER {table_name}_updated_at
  BEFORE UPDATE ON public.{table_name}
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## Finpa Tables Reference

### transactions
```sql
CREATE TABLE public.transactions (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  description TEXT NOT NULL,
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  type        TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category_id TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
```

### budgets
```sql
CREATE TABLE public.budgets (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category_id TEXT NOT NULL,
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  month       DATE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (user_id, category_id, month)
);
```

### goals
```sql
CREATE TABLE public.goals (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id        UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title          TEXT NOT NULL,
  target_amount  NUMERIC(12, 2) NOT NULL CHECK (target_amount > 0),
  current_amount NUMERIC(12, 2) DEFAULT 0 CHECK (current_amount >= 0),
  deadline       DATE,
  completed      BOOLEAN DEFAULT FALSE,
  created_at     TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at     TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
```

## Dart Model from Table

For each Supabase table, generate the matching model:

```dart
class TransactionModel {
  final String id;
  final String userId;
  final String description;
  final double amount;
  final String type;
  final String categoryId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id:          json['id'] as String,
        userId:      json['user_id'] as String,
        description: json['description'] as String,
        amount:      (json['amount'] as num).toDouble(),
        type:        json['type'] as String,
        categoryId:  json['category_id'] as String,
        createdAt:   DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'user_id':     userId,
    'description': description,
    'amount':      amount,
    'type':        type,
    'category_id': categoryId,
  };

  Transaction toEntity() => Transaction(
    id:          id,
    userId:      userId,
    description: description,
    amount:      amount,
    type:        type == 'income'
                   ? TransactionType.income
                   : TransactionType.expense,
    categoryId:  categoryId,
    createdAt:   createdAt,
  );
}
```

## SQL Type → Dart Type Mapping

| Supabase SQL | Dart |
|---|---|
| `UUID` | `String` |
| `TEXT` | `String` |
| `NUMERIC` / `FLOAT8` | `double` — usar `(json['x'] as num).toDouble()` |
| `INT` / `INT4` | `int` |
| `BOOLEAN` | `bool` |
| `TIMESTAMPTZ` | `DateTime` — usar `DateTime.parse(...)` |
| `DATE` | `DateTime` — solo año/mes/día |
| `JSONB` | `Map<String, dynamic>` |

## Useful Supabase Queries for Finpa

```dart
// Monthly summary
final data = await client
    .from('transactions')
    .select()
    .eq('user_id', userId)
    .gte('created_at', startOfMonth.toIso8601String())
    .lte('created_at', endOfMonth.toIso8601String());

// Category expenses
final expenses = await client
    .from('transactions')
    .select('category_id, amount')
    .eq('user_id', userId)
    .eq('type', 'expense')
    .gte('created_at', startOfMonth.toIso8601String());

// Recent transactions (limit 5)
final recent = await client
    .from('transactions')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false)
    .limit(5);
```

## Additional Resources

- **`references/rls-patterns.md`** — Advanced RLS patterns for shared data
