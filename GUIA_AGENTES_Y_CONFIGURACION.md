# Guía de Configuración — Finpa AI Dev Environment

> Proyecto: Finpa — App financiera Flutter
> Fecha: 2026-03-24
> Herramienta: Claude Code CLI

---

## Índice

1. [Qué se configuró](#1-qué-se-configuró)
2. [Estructura de archivos de configuración](#2-estructura-de-archivos-de-configuración)
3. [CLAUDE.md — El cerebro del proyecto](#3-claudemd--el-cerebro-del-proyecto)
4. [Sub-agentes especializados](#4-sub-agentes-especializados)
5. [MCP Servers](#5-mcp-servers)
6. [Permisos (settings.json)](#6-permisos-settingsjson)
7. [Estructura Clean Architecture + DDD](#7-estructura-clean-architecture--ddd)
8. [Cómo usar los agentes en la práctica](#8-cómo-usar-los-agentes-en-la-práctica)
9. [Cómo agregar nuevos agentes](#9-cómo-agregar-nuevos-agentes)
10. [Cómo agregar nuevos MCP Servers](#10-cómo-agregar-nuevos-mcp-servers)
11. [Flujo de desarrollo recomendado](#11-flujo-de-desarrollo-recomendado)

---

## 1. Qué se configuró

Se montó un entorno de desarrollo con IA que incluye:

| Qué | Dónde | Para qué |
|---|---|---|
| Proyecto Flutter base | `/` raíz del proyecto | App Finpa con Android + iOS |
| `CLAUDE.md` | `/CLAUDE.md` | Contexto permanente del proyecto para Claude |
| Sub-agentes | `/.claude/agents/` | Agentes IA especializados por rol |
| Settings del proyecto | `/.claude/settings.json` | Permisos y MCP servers |
| Core layer | `/lib/core/` | Infraestructura base Clean Architecture |
| Estructura DDD | `/lib/features/` | Bounded contexts por feature |
| Dependencias | `/pubspec.yaml` | Stack completo BLoC, DI, dartz, etc. |

---

## 2. Estructura de archivos de configuración

```
Finpa/
├── CLAUDE.md                        ← Contexto permanente del proyecto
├── GUIA_AGENTES_Y_CONFIGURACION.md  ← Este documento
├── pubspec.yaml                     ← Dependencias Flutter
│
├── .claude/
│   ├── settings.json                ← Permisos y MCP servers del proyecto
│   └── agents/
│       ├── flutter-architect.md     ← Agente: arquitectura Clean + DDD
│       ├── domain-modeler.md        ← Agente: modelado del dominio DDD
│       ├── flutter-ui.md            ← Agente: UI, BLoC, widgets
│       └── test-writer.md           ← Agente: tests unitarios y de BLoC
│
└── lib/
    ├── main.dart
    ├── app.dart
    ├── core/
    │   ├── errors/       failures.dart
    │   ├── usecase/      usecase.dart
    │   ├── network/      dio_client.dart
    │   ├── theme/        app_theme.dart
    │   ├── constants/    app_constants.dart
    │   └── di/           injection_container.dart
    └── features/
        └── auth/
            ├── domain/
            ├── data/
            └── presentation/
```

---

## 3. CLAUDE.md — El cerebro del proyecto

### Qué es
`CLAUDE.md` es un archivo especial que Claude Code lee **automáticamente** al inicio de cada conversación dentro de este proyecto. Funciona como la memoria permanente del proyecto.

### Cómo funciona
```
Sin CLAUDE.md:
  Usuario: "crea una nueva feature"
  Claude: no sabe qué arquitectura usa, qué stack tiene, ni las reglas

Con CLAUDE.md:
  Usuario: "crea una nueva feature"
  Claude: ya sabe que es Flutter + Clean Arch + DDD + BLoC + dartz + get_it
          y aplica todas las reglas automáticamente
```

### Qué tiene el CLAUDE.md de Finpa
- Descripción del proyecto y plataformas objetivo
- Diagrama de capas (Domain → Data → Presentation)
- Estructura de carpetas esperada
- **Reglas de arquitectura obligatorias** (ej: Domain nunca importa de Data)
- Convenciones de nombres (`UserModel`, `UserRepository`, `AuthBloc`)
- Stack técnico completo con versiones
- Lista de sub-agentes disponibles

### Cuándo editarlo
Edita `CLAUDE.md` cuando:
- Agregar una nueva feature permanente al proyecto
- Cambiar una decisión de arquitectura
- Incorporar una nueva librería al stack
- Definir nuevas convenciones de código

---

## 4. Sub-agentes especializados

### Qué son
Los sub-agentes son archivos `.md` en `.claude/agents/` que definen roles especializados de IA. Cada agente tiene:
- Un **nombre** (cómo invocarlo)
- Una **descripción** (cuándo Claude lo activa automáticamente)
- Un **prompt del sistema** (instrucciones de comportamiento del agente)

### Cuándo se activan
Claude Code puede activar sub-agentes de dos formas:
1. **Automáticamente** — cuando detecta que la tarea coincide con la descripción del agente
2. **Manualmente** — cuando el usuario lo solicita explícitamente

### Agentes configurados

#### `flutter-architect`
```
Archivo: .claude/agents/flutter-architect.md
```
**Cuándo usarlo:**
- Diseñar la estructura de una nueva feature
- Decidir qué va en Domain vs Data vs Presentation
- Evaluar si el código respeta Clean Architecture
- Planificar bounded contexts DDD
- Resolver dudas como "¿dónde va esta clase?"

**Ejemplo de uso:**
```
"necesito agregar la feature de transacciones, ayúdame a diseñar la arquitectura"
→ Claude activa flutter-architect automáticamente
```

---

#### `domain-modeler`
```
Archivo: .claude/agents/domain-modeler.md
```
**Cuándo usarlo:**
- Crear entidades del dominio (`Transaction`, `Account`, `User`)
- Crear Value Objects con validación (`Email`, `MoneyAmount`, `Password`)
- Definir interfaces de repositorios
- Crear casos de uso (UseCases)
- Modelar aggregates y domain events

**Ejemplo de uso:**
```
"crea la entidad Transaction con sus value objects"
→ Claude activa domain-modeler automáticamente
```

**Qué genera:**
```dart
// Entidad con Equatable
class Transaction extends Equatable { ... }

// Value Object con validación Either
class MoneyAmount extends Equatable {
  static Either<Failure, MoneyAmount> create(double value) { ... }
}

// Interfaz del repositorio
abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
}

// UseCase
class GetTransactionsUseCase implements UseCase<List<Transaction>, NoParams> { ... }
```

---

#### `flutter-ui`
```
Archivo: .claude/agents/flutter-ui.md
```
**Cuándo usarlo:**
- Crear páginas Flutter (Screens)
- Crear widgets reutilizables
- Implementar BLoC completo (event + state + bloc)
- Configurar rutas con GoRouter
- Diseñar UI con Material Design 3

**Ejemplo de uso:**
```
"crea la pantalla de login con su BLoC"
→ Claude activa flutter-ui automáticamente
```

**Qué genera:**
```dart
// BLoC completo: AuthEvent, AuthState, AuthBloc
// LoginPage con BlocBuilder + BlocListener
// Widgets separados y reutilizables
```

---

#### `test-writer`
```
Archivo: .claude/agents/test-writer.md
```
**Cuándo usarlo:**
- Escribir tests de UseCases
- Escribir tests de BLoC con `bloc_test`
- Escribir tests de Value Objects
- Escribir tests de widgets

**Ejemplo de uso:**
```
"escribe los tests para AuthBloc"
→ Claude activa test-writer automáticamente
```

**Qué genera:**
```dart
// Tests con mocktail
// Patrón AAA (Arrange-Act-Assert)
// blocTest con emit expectations
// Tests de happy path + error path
```

---

### Cómo están estructurados los archivos de agente

```markdown
---
name: nombre-del-agente           ← identificador único
description: Una línea clara de   ← CRÍTICO: Claude usa esto para decidir
             cuándo usar este       cuándo activar el agente
             agente
---

# Título del Agente

Aquí va el prompt del sistema:
- Rol del agente
- Reglas que debe seguir
- Ejemplos de código que genera
- Contexto del proyecto
```

> **La `description` en el frontmatter es lo más importante.**
> Claude la lee para decidir si debe usar este agente o no.
> Debe ser específica y mencionar casos de uso concretos.

---

## 5. MCP Servers

### Qué son los MCP Servers
MCP (Model Context Protocol) son servidores externos que extienden las capacidades de Claude con herramientas adicionales. Se conectan vía `npx` o procesos locales.

### MCP Servers configurados

#### `sequential-thinking`
```json
"sequential-thinking": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
}
```
**Para qué sirve:** Permite a Claude razonar paso a paso en problemas complejos. Muy útil para:
- Diseñar arquitecturas complejas
- Planificar implementaciones con múltiples dependencias
- Resolver problemas que requieren pensar en cadena

**Sin API key** — funciona inmediatamente.

---

#### `filesystem`
```json
"filesystem": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem",
           "C:/Users/EndersonFlorian/Documents/Enderson/Proyecto/Finpa"]
}
```
**Para qué sirve:** Acceso directo al sistema de archivos del proyecto. Complementa las herramientas nativas de Claude Code con capacidades adicionales de lectura/escritura.

---

### Dónde se configuran los MCP
```
.claude/settings.json  ← MCP solo para este proyecto
~/.claude/settings.json ← MCP global para todos los proyectos
```

---

## 6. Permisos (settings.json)

### Archivo: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(flutter *)",
      "Bash(dart *)",
      "Bash(git *)",
      "Bash(mkdir *)",
      ...
    ]
  },
  "mcpServers": { ... }
}
```

### Para qué sirve
Define qué comandos Bash puede ejecutar Claude **sin pedir confirmación** al usuario. Los comandos en `allow` se ejecutan directamente.

### Permisos configurados para Finpa
| Permiso | Permite |
|---|---|
| `Bash(flutter *)` | Todos los comandos flutter (run, pub, build, test...) |
| `Bash(dart *)` | Comandos dart (format, analyze, test...) |
| `Bash(git *)` | Control de versiones |
| `Bash(mkdir *)` | Crear carpetas |
| `Bash(ls/cp/mv/rm *)` | Operaciones de archivos |

### Agregar más permisos
```json
"allow": [
  "Bash(flutter *)",
  "Bash(dart *)",
  "Bash(npm *)",        ← agregar aquí
  "Bash(adb *)"         ← y aquí
]
```

---

## 7. Estructura Clean Architecture + DDD

### Diagrama de capas
```
┌─────────────────────────────────────┐
│           PRESENTATION              │  BLoC, Pages, Widgets
│  flutter_bloc, go_router, widgets   │
├─────────────────────────────────────┤
│              DATA                   │  Implementaciones
│  dio, shared_prefs, models, repos   │
├─────────────────────────────────────┤
│             DOMAIN                  │  Núcleo del negocio
│  entities, value_objects, usecases  │  ← Sin dependencias externas
└─────────────────────────────────────┘
```

### Regla de dependencia (CRÍTICA)
```
Presentation → Data → Domain    ← permitido
Domain → Data                   ← PROHIBIDO
Domain → Presentation           ← PROHIBIDO
```

### Archivos core creados

| Archivo | Qué hace |
|---|---|
| `core/errors/failures.dart` | Clases de error: `Failure`, `ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure` |
| `core/usecase/usecase.dart` | Clase base `UseCase<Type, Params>` y `NoParams` |
| `core/network/dio_client.dart` | Cliente HTTP configurado con Dio + logger |
| `core/theme/app_theme.dart` | Tema Material 3 con light/dark mode |
| `core/constants/app_constants.dart` | Constantes globales (URL, keys, timeouts) |
| `core/di/injection_container.dart` | Setup de GetIt + Injectable |

### Estructura por feature (DDD Bounded Context)
```
lib/features/{feature}/
├── domain/              ← PRIMERO se diseña esto
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/    ← Solo interfaces
│   └── usecases/
├── data/                ← Implementa el contrato del domain
│   ├── models/          ← DTOs (extienden entidades)
│   ├── datasources/     ← remote + local
│   └── repositories/    ← Implementaciones
└── presentation/        ← Consume el domain via BLoC
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

## 8. Cómo usar los agentes en la práctica

### Activación automática
Simplemente describe tu tarea con naturalidad:

```
"necesito la feature de autenticación con login por email"
→ Claude activa flutter-architect para diseñar la estructura
→ Luego domain-modeler para crear User entity y Email value object
→ Luego flutter-ui para crear LoginPage + AuthBloc
→ Luego test-writer para los tests
```

### Activación manual (más control)
```
"usa el agente domain-modeler para crear la entidad Transaction"
"con flutter-architect diseña el bounded context de transacciones"
"usa test-writer y escribe los tests para GetTransactionsUseCase"
```

### Flujo de trabajo típico por feature
```
1. flutter-architect  → diseña la estructura de la feature
2. domain-modeler     → crea entidades, value objects, interfaces
3. flutter-ui         → implementa BLoC + páginas + widgets
4. test-writer        → escribe los tests
```

---

## 9. Cómo agregar nuevos agentes

### Paso 1: Crear el archivo
```
.claude/agents/nombre-agente.md
```

### Paso 2: Estructura del archivo
```markdown
---
name: nombre-agente
description: Descripción específica de cuándo usar este agente.
             Menciona casos de uso concretos para que Claude
             sepa cuándo activarlo automáticamente.
---

# Título

Eres un experto en [especialidad].

## Tu rol
[Descripción detallada]

## Reglas
- Regla 1
- Regla 2

## Ejemplos de código
[Código de ejemplo]
```

### Paso 3: Sin reinicio necesario
Claude Code detecta los agentes automáticamente. No hay que reiniciar.

### Ideas de agentes adicionales para Finpa

| Agente | Descripción sugerida |
|---|---|
| `flutter-router` | Configura rutas GoRouter, guards de autenticación y deep links |
| `flutter-theme` | Diseña sistema de colores, tipografía y componentes de design system |
| `data-layer` | Implementa datasources remotos con Dio y locales con SharedPreferences |
| `localization` | Configura internacionalización con arb files y flutter_localizations |
| `ci-cd` | Configura GitHub Actions para Flutter: tests, build y deploy |
| `performance` | Analiza y optimiza rendimiento: lazy loading, const widgets, rebuilds |

---

## 10. Cómo agregar nuevos MCP Servers

### En `.claude/settings.json` (solo este proyecto)
```json
{
  "mcpServers": {
    "nombre-mcp": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-nombre"]
    }
  }
}
```

### En `~/.claude/settings.json` (global, todos los proyectos)
Mismo formato, pero aplica a todos los proyectos.

### MCP Servers recomendados para Flutter/Finpa

| MCP | Instalación | Para qué |
|---|---|---|
| `sequential-thinking` | ya instalado | Razonamiento complejo en cadena |
| `filesystem` | ya instalado | Acceso al sistema de archivos |
| `brave-search` | requiere API key | Buscar docs, paquetes pub.dev |
| `github` | requiere token | Gestión de issues, PRs, releases |
| `sqlite` | sin API key | Explorar bases de datos locales |

### Agregar brave-search (ejemplo con API key)
```json
"brave-search": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-brave-search"],
  "env": {
    "BRAVE_API_KEY": "tu-api-key-aqui"
  }
}
```

---

## 11. Flujo de desarrollo recomendado

### Para cada nueva feature en Finpa

```
PASO 1 — Diseño (flutter-architect)
  "diseña la feature de [nombre] con Clean Architecture"
  → Obtienes: diagrama de carpetas + contratos de dominio

PASO 2 — Domain Layer (domain-modeler)
  "crea las entidades y value objects para [feature]"
  → Obtienes: entities, value objects, repository interfaces, usecases

PASO 3 — Data Layer
  "implementa el data layer para [feature]"
  → Obtienes: models (DTOs), datasources remote+local, repository impl

PASO 4 — Presentation Layer (flutter-ui)
  "crea las páginas y BLoC para [feature]"
  → Obtienes: BLoC completo + páginas + widgets

PASO 5 — Tests (test-writer)
  "escribe los tests para [feature]"
  → Obtienes: tests unitarios + tests de BLoC

PASO 6 — Code Generation
  flutter pub run build_runner build --delete-conflicting-outputs
  → Genera: injection_container.config.dart, *.freezed.dart, *.g.dart
```

### Comandos útiles del proyecto

```bash
# Instalar dependencias
flutter pub get

# Generar código (DI, freezed, json)
flutter pub run build_runner build --delete-conflicting-outputs

# Correr en modo watch (regenera al guardar)
flutter pub run build_runner watch --delete-conflicting-outputs

# Ejecutar tests
flutter test

# Analizar código
flutter analyze

# Formatear código
dart format lib/ test/
```

---

## Resumen visual

```
Claude Code CLI
│
├── Lee CLAUDE.md automáticamente
│   └── Sabe: stack, arquitectura, reglas, convenciones
│
├── Sub-agentes (.claude/agents/)
│   ├── flutter-architect  → "diseña la feature X"
│   ├── domain-modeler     → "crea la entidad Y"
│   ├── flutter-ui         → "crea la página Z con BLoC"
│   └── test-writer        → "escribe tests para W"
│
├── MCP Servers (.claude/settings.json)
│   ├── sequential-thinking → razonamiento en cadena
│   └── filesystem          → acceso a archivos
│
└── Proyecto Flutter
    ├── core/               → infraestructura base
    └── features/           → bounded contexts DDD
        └── {feature}/
            ├── domain/     ← diseñar primero
            ├── data/       ← implementar segundo
            └── presentation/ ← conectar último
```

---

*Documento generado por Claude Code — Proyecto Finpa*
