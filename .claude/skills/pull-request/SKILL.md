---
name: pull-request
description: This skill should be used when the user asks to "crear pull request", "hacer PR", "abrir PR", "subir cambios", "push y PR", "crear rama y PR", "commit y pull request", or wants to commit changes, push a branch, and open a pull request for the Finpa project.
version: 1.0.0
---

# Pull Request — Finpa

Create a complete pull request: commit staged changes, push branch, and open PR on GitHub following Finpa conventions.

## Step-by-Step Process

### Step 1 — Inspect current state

Run these in parallel before doing anything:

```bash
git status
git diff HEAD
git branch --show-current
git log --oneline -5
```

### Step 2 — Create or use a feature branch

Never commit directly to `main` or `develop`.

**Nomenclatura obligatoria del proyecto Finpa:**

```
dev-eflorian-{TIPO}-{DD}{MM}{YYYY}{HH}{MM}{SS}
```

| Parte | Descripción | Ejemplo |
|-------|-------------|---------|
| `TIPO` | `FT` feature · `BG` bugfix · `HT` hotfix | `FT` |
| `DD` | Día con 2 dígitos | `06` |
| `MM` | Mes con 2 dígitos | `05` |
| `YYYY` | Año con 4 dígitos | `2026` |
| `HH` | Hora con 2 dígitos | `09` |
| `MM` | Minuto con 2 dígitos | `11` |
| `SS` | Primeros 2 dígitos de los segundos | `56` |

Ejemplo: `dev-eflorian-FT-06052026091156`

Antes de crear el branch, obtener el timestamp exacto:

```powershell
# PowerShell
Get-Date -Format 'ddMMyyyyHHmmss'
```

```bash
# Bash
date +%d%m%Y%H%M%S
```

Usar los primeros 2 dígitos del resultado como SS. Luego crear el branch:

```bash
git checkout -b dev-eflorian-{TIPO}-{DDMMYYYYHHmm}{SS}
```

### Step 3 — Stage and commit

```bash
# Stage specific files (never git add -A blindly)
git add lib/features/{feature}/
git add lib/router/app_router.dart   # if routes changed

# Never stage:
# .env  ← contains secrets
# *.g.dart  ← generated files
# build/  ← build artifacts

# Commit with conventional format
git commit -m "$(cat <<'EOF'
{type}({scope}): {short description}

{optional body explaining WHY, not what}

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Commit message format:

```
feat(transactions): add transactions list screen with skeleton loading
fix(dashboard): fix balance card showing null when Supabase not initialized
refactor(router): replace double underscore params with single underscore
chore(deps): update go_router to 13.2.5
```

### Step 4 — Push branch

```bash
git push -u origin {branch-name}
```

### Step 5 — Create Pull Request with gh CLI

```bash
gh pr create \
  --title "{type}({scope}): {description}" \
  --body "$(cat <<'EOF'
## Resumen
- Bullet point 1
- Bullet point 2

## Cambios
- `lib/...` — descripción del cambio
- `lib/...` — descripción del cambio

## Cómo probar
- [ ] Paso 1
- [ ] Paso 2
- [ ] Verificar en modo dark y light

## Screenshots
<!-- Agregar si hay cambios visuales -->

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

## PR Title Convention

```
feat(dashboard): add category grid with progress bars
fix(auth): handle Supabase uninitialized error on splash screen
refactor(theme): replace CardTheme with CardThemeData
chore(agents): add qa-engineer and pull-request skills
```

## What to Check Before Opening PR

- [ ] `flutter analyze` sin errores (solo infos son aceptables)
- [ ] `flutter build web` compila correctamente
- [ ] No hay archivos `.env` o secretos en el commit
- [ ] No hay archivos generados (`*.g.dart`, `build/`)
- [ ] El branch name sigue la convención `dev-eflorian-{FT|BG|HT}-DDMMYYYYHHMM{SS}`
- [ ] El commit message sigue el formato convencional

## If the Repo Has No Remote Yet

```bash
# Initialize git if needed
git init
git branch -M main

# Add remote (replace with actual repo URL)
git remote add origin https://github.com/{user}/finpa.git

# First push
git push -u origin main
```

## Quick Commands Reference

```bash
# Check what would be committed
git status
git diff --cached

# Undo last commit (keep changes)
git reset --soft HEAD~1

# See open PRs
gh pr list

# Check PR status
gh pr status

# Merge PR from CLI
gh pr merge --squash
```
