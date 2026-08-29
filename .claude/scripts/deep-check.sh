#!/usr/bin/env bash
# Revisión profunda, A DEMANDA. Lo que se sacó de los gates por lento:
# build de producción y auditoría de dependencias.
#
# Los gates por tarea deben ser rápidos o se acaban saltando. Esto se corre
# cuando tiene sentido: al cerrar una historia, tras actualizar dependencias,
# o cuando algo huele raro. No en cada archivo tocado.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

FAIL=0
step()  { echo ""; echo "── $1"; }
check() { if "$@"; then echo "  ✔ ok"; else echo "  ✘ FALLA"; FAIL=1; fi }

while IFS= read -r B; do
  [ -z "$B" ] && continue
  echo ""; echo "═══ BACKEND · $(inst_name "$B")"
  cd "$B" || continue
  step "Dependencias sin CVE conocidos"
  check composer audit --no-interaction
done <<< "$BACKENDS"

while IFS= read -r F; do
  [ -z "$F" ] && continue
  echo ""; echo "═══ FRONTEND · $(inst_name "$F")"
  cd "$F" || continue
  step "Build de producción"
  check npm run build
  step "Dependencias sin vulnerabilidades altas"
  check npm audit --audit-level=high
done <<< "$FRONTENDS"

echo ""
[ "$FAIL" -eq 0 ] && echo "REVISIÓN PROFUNDA: VERDE" || echo "REVISIÓN PROFUNDA: ROJO"
exit "$FAIL"
