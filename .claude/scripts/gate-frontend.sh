#!/usr/bin/env bash
# Gate de frontend. Recorre TODAS las instancias de frontend del repositorio.
# Uso:  gate-frontend.sh                 → todas
#       gate-frontend.sh admin_frontend  → solo esa
# Sin 'npm run build' ni 'npm audit': ambos viven en deep-check.sh, a demanda.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

TARGET="${1:-}"
if [ "$N_FRONTENDS" -eq 0 ]; then
  echo "No hay frontend en este repositorio (layout: $LAYOUT). Gate omitido."
  exit 0
fi

TOTAL=0
step()  { echo ""; echo "── $1"; }
check() { if "$@" >/dev/null 2>&1; then echo "  ✔ ok"; else echo "  ✘ FALLA"; FAIL=1; fi }

while IFS= read -r F; do
  [ -z "$F" ] && continue
  NAME="$(inst_name "$F")"
  [ -n "$TARGET" ] && [ "$NAME" != "$TARGET" ] && continue

  echo ""; echo "═══ GATE FRONTEND · $NAME  ($LAYOUT)"
  cd "$F" || continue
  FAIL=0

  step "Ningún componente importa axios directamente"
  check bash -c '! grep -rIn "from '\''axios'\''" src/components src/views src/layouts 2>/dev/null | grep .'

  step "Sin console.log en el código fuente"
  check bash -c '! grep -rIn "console\.log" src/ --include="*.vue" --include="*.js" | grep .'

  step "Colores como tokens, no hardcodeados"
  check bash -c '! grep -rInE "(bg|text|border)-\[#[0-9a-fA-F]{3,8}\]" src/ --include="*.vue" | grep .'

  step "Todas las rutas son lazy"
  check bash -c '! grep -rnE "^import .* from .*[\"'\''].*/views/" src/router/ 2>/dev/null | grep .'

  step "Sintaxis de los .vue y .js parseable"
  check bash -c 'find src -name "*.js" -print0 | xargs -0 -r -n1 node --check'

  step "gsap solo se importa desde composables/"
  check bash -c '! grep -rIn "from .gsap" src/ --include="*.vue" --include="*.js" 2>/dev/null | grep -v "^src/composables/" | grep .'

  step "Sin markers de ScrollTrigger en el código"
  check bash -c '! grep -rInE "markers:[[:space:]]*true" src/ --include="*.vue" --include="*.js" 2>/dev/null | grep .'

  echo ""
  [ "$FAIL" -eq 0 ] && echo "  → $NAME: VERDE" || { echo "  → $NAME: ROJO"; TOTAL=1; }
done <<< "$FRONTENDS"

echo ""
[ "$TOTAL" -eq 0 ] && echo "GATE FRONTEND: VERDE" || echo "GATE FRONTEND: ROJO"
exit "$TOTAL"
