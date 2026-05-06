# Workflow: Crear Branch y PR

Procedimiento estándar para abrir un Pull Request en el proyecto Finpa.

El archivo ejecutable vive en `.claude/workflows/crear_pr.md` — esta documentación es la referencia de estudio.

---

## Nomenclatura del branch

Formato: `dev-eflorian-{TIPO}-{DD}{MM}{YYYY}{HH}{MM}{SS}`

| Parte | Descripción | Ejemplo |
|-------|-------------|---------|
| `TIPO` | `FT` feature · `BG` bugfix · `HT` hotfix | `FT` |
| `DD` | Día con 2 dígitos | `06` |
| `MM` | Mes con 2 dígitos | `05` |
| `YYYY` | Año con 4 dígitos | `2026` |
| `HH` | Hora con 2 dígitos | `09` |
| `MM` | Minuto con 2 dígitos | `11` |
| `SS` | Primeros 2 dígitos de los segundos | `56` |

**Ejemplo completo:** `dev-eflorian-FT-06052026091156`

> Los 2 dígitos de segundos al final diferencian dos branches creados en el mismo minuto.

---

## Por qué este formato

- `dev-` deja claro que es una rama de desarrollo, no main ni release
- `eflorian` identifica al autor sin ambigüedad
- `FT/BG/HT` clasifica el tipo de cambio de un vistazo
- El timestamp completo `DDMMYYYYHHMM` hace cada rama única y ordenable cronológicamente
- Los segundos `SS` son el seguro anti-colisión si hay dos ramas en el mismo minuto

---

## Cómo obtener el timestamp

```powershell
# PowerShell — devuelve DDMMYYYYHHmmSS
Get-Date -Format 'ddMMyyyyHHmmss'
# Ejemplo de salida: 06052026091156
# Usar los 2 primeros dígitos del final (56) como SS
```

```bash
# Bash / Git Bash
date +%d%m%Y%H%M%S
# Ejemplo de salida: 06052026091156
```

---

## Pasos completos

```bash
# 1. Crear el branch
git checkout -b dev-eflorian-FT-06052026091156

# 2. Verificar qué cambios hay
git status
git diff --staged

# 3. Commit (si hay cambios sin commitear)
git add lib/features/mi_feature/
git commit -m "feat: descripción del cambio"

# 4. Push con tracking
git push -u origin dev-eflorian-FT-06052026091156

# 5. Abrir el PR apuntando a main
gh pr create --base main \
  --title "feat: descripción del PR" \
  --body "## Summary
- Qué cambió y por qué

## Test plan
- [ ] Probado en Android
- [ ] Probado en iOS"
```

---

## Checklist antes de enviar el PR

- [ ] El nombre de la rama sigue el formato exacto `dev-eflorian-{FT|BG|HT}-DDMMYYYYHHMM{SS}`
- [ ] `flutter analyze` sin warnings
- [ ] `flutter test` todos pasan
- [ ] Si hay cambios en `@HiveType` o `@Riverpod`: se corrió `build_runner`
- [ ] Si hay strings nuevos: están en `es.json` y `en.json`
- [ ] PR apunta a `main` (no a otra rama)
- [ ] El PR se creó correctamente y aparece en GitHub

---

## Cómo invocar el workflow desde Claude

En cualquier conversación nueva del proyecto:

```
ejecuta el workflow crear_pr
```

Claude leerá `.claude/workflows/crear_pr.md` y guiará el proceso paso a paso.
