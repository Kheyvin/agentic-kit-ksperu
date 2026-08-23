#!/usr/bin/env bash
# Gate de frontend. Funciona con cualquier layout. != 0 si algo no pasa.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

if [ -z "$FRONTEND_DIR" ]; then
  echo "No hay frontend en este repositorio (layout: $LAYOUT). Gate omitido."
  exit 0
fi
cd "$FRONTEND_DIR"
echo "Gate frontend en: $FRONTEND_DIR  (layout: $LAYOUT)"

FAIL=0
step()  { echo ""; echo "── $1"; }
check() { if "$@" >/dev/null 2>&1; then echo "  ✔ ok"; else echo "  ✘ FALLA"; FAIL=1; fi }

step "Build de producción"
check npm run build

step "Ningún componente importa axios directamente"
check bash -c '! grep -rIn "from '\''axios'\''" src/components src/views src/layouts 2>/dev/null | grep .'

step "Sin console.log en el código fuente"
check bash -c '! grep -rIn "console\.log" src/ --include="*.vue" --include="*.js" | grep .'

step "Colores como tokens, no hardcodeados"
check bash -c '! grep -rInE "(bg|text|border)-\[#[0-9a-fA-F]{3,8}\]" src/ --include="*.vue" | grep .'

step "Todas las rutas son lazy"
check bash -c '! grep -nE "^import .* from .*[\"'\''].*/views/" src/router/routes.js 2>/dev/null | grep .'

step "Dependencias sin vulnerabilidades altas"
check npm audit --audit-level=high

echo ""
[ "$FAIL" -eq 0 ] && echo "GATE FRONTEND: VERDE" || echo "GATE FRONTEND: ROJO"
exit "$FAIL"
