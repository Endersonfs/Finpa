# Workflow: Crear branch y PR

Cuando el usuario diga "ejecuta crear_pr", "crea un PR", "nuevo branch" o "tarea PR", seguir estos pasos exactamente.

## Nomenclatura del branch

Formato: `dev-eflorian-{TIPO}-{DD}{MM}{YYYY}{HH}{MM}{SS}`

| Parte | Descripción |
|-------|-------------|
| TIPO  | `FT` (feature) · `BG` (bugfix) · `HT` (hotfix) — mayúsculas |
| DD    | Día con 2 dígitos |
| MM    | Mes con 2 dígitos |
| YYYY  | Año con 4 dígitos |
| HH    | Hora con 2 dígitos |
| MM    | Minuto con 2 dígitos |
| SS    | Primeros 2 dígitos de los segundos |

Ejemplo: `dev-eflorianFT-06052026091156`

## Pasos

1. Preguntar al usuario: **tipo** (FT / BG / HT) y **título del PR**
2. Obtener el timestamp en el momento exacto de ejecución:
   ```powershell
   # PowerShell
   Get-Date -Format 'ddMMyyyyHHmmss'
   ```
   ```bash
   # Bash
   date +%d%m%Y%H%M%S
   ```
   Usar solo los **2 primeros dígitos** del resultado para los segundos (SS).
3. Construir el nombre: `dev-eflorian-{TIPO}-{DDMMYYYYHHmm}{SS}`
4. Crear el branch y moverse a él:
   ```bash
   git checkout -b {nombre}
   ```
5. Revisar estado con `git status` y `git diff --staged`
6. Si hay cambios, pedir mensaje de commit al usuario y hacer commit
7. Push con tracking:
   ```bash
   git push -u origin {nombre}
   ```
8. Crear el PR apuntando a `main`:
   ```bash
   gh pr create --base main --title "{título}" --body "..."
   ```

## Checklist de verificación

- [ ] El nombre de la rama sigue el formato exacto `dev-eflorian{FT|BG|HT}-DDMMYYYYHHMM{SS}`
- [ ] El PR se creó correctamente en GitHub y aparece en la lista de PRs
