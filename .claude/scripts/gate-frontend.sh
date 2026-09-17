#!/usr/bin/env bash
# Gate de frontend. Uso: gate-frontend.sh [instancia]   (sin argumento = todas)
# Bloquea solo lo que rompe (no compila) o viola la arquitectura de red. El resto avisa.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"
TARGET="${1:-}"
[ "$N_FRONTENDS" -eq 0 ] && { echo "Sin frontend en el repositorio (layout: $LAYOUT). Gate omitido."; exit 0; }

TOTAL=0; FAIL=0
run() {
  local title="$1" mode="$2"; shift 2
  local out rc; out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then echo "  ✔ $title"; return 0; fi
  if [ "$mode" = "avisa" ]; then echo "  ⚠ $title (no bloquea)"; else echo "  ✘ $title"; FAIL=1; fi
  printf '%s\n' "$out" | tail -n 25 | sed 's/^/      /'
}
build() {
  [ -d node_modules ] || { echo "falta node_modules: ejecuta npm install"; return 1; }
  ls vite.config.* >/dev/null 2>&1 || { echo "sin vite.config: build omitido"; return 0; }
  npx vite build --logLevel error
}
no_axios_in_components() { ! grep -rIn "from ['\"]axios['\"]" src/components src/views src/layouts 2>/dev/null | grep .; }
lazy_routes()    { ! grep -rnE "^import .* from .*/views/" src/router/ 2>/dev/null | grep .; }
no_console_log() { ! grep -rIn 'console\.log' src/ --include='*.vue' --include='*.js' --include='*.ts' | grep .; }
gsap_ok() {
  ! { grep -rIn "from ['\"]gsap" src/ --include='*.vue' --include='*.js' --include='*.ts' 2>/dev/null | grep -v '^src/composables/'
      grep -rInE 'markers:\s*true' src/ --include='*.vue' --include='*.js' --include='*.ts' 2>/dev/null; } | grep .
}

while IFS= read -r F; do
  [ -z "$F" ] && continue
  NAME="$(inst_name "$F")"; [ -n "$TARGET" ] && [ "$NAME" != "$TARGET" ] && continue
  echo "═══ GATE FRONTEND · $NAME"
  cd "$F" || continue
  FAIL=0
  run "Compila con Vite (sintaxis e imports)"     bloquea build
  run "Ningún componente importa axios"           bloquea no_axios_in_components
  run "Rutas lazy"                                avisa   lazy_routes
  run "Sin console.log"                           avisa   no_console_log
  run "GSAP solo en composables y sin markers"    avisa   gsap_ok
  [ "$FAIL" -eq 0 ] && echo "  → $NAME: VERDE" || { echo "  → $NAME: ROJO"; TOTAL=1; }
done <<< "$FRONTENDS"

[ "$TOTAL" -eq 0 ] && echo "GATE FRONTEND: VERDE" || echo "GATE FRONTEND: ROJO"
exit "$TOTAL"
