#!/usr/bin/env bash
# Gate de backend. Uso: gate-backend.sh [instancia]   (sin argumento = todas)
# Imprime la salida del paso que falla: el agente arregla lo que ve, no lo que adivina.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"
TARGET="${1:-}"
[ "$N_BACKENDS" -eq 0 ] && { echo "Sin backend en el repositorio (layout: $LAYOUT). Gate omitido."; exit 0; }

TOTAL=0; FAIL=0
run() {  # run "título" bloquea|avisa comando...
  local title="$1" mode="$2"; shift 2
  local out rc; out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then echo "  ✔ $title"; return 0; fi
  if [ "$mode" = "avisa" ]; then echo "  ⚠ $title (no bloquea)"; else echo "  ✘ $title"; FAIL=1; fi
  printf '%s\n' "$out" | tail -n 25 | sed 's/^/      /'
}
changed_php() {  # PHP modificados o nuevos respecto a HEAD; sin git o sin commits, todos
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    { git diff --name-only --relative HEAD -- src; git ls-files --others --exclude-standard -- src; } 2>/dev/null | grep '\.php$' | sort -u
  else
    find src -name '*.php'
  fi
}
lint_php() {
  local f rc=0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    php -l "$f" >/dev/null 2>&1 || { php -l "$f" 2>&1 | head -3; rc=1; }
  done < <(changed_php)
  return $rc
}
no_secrets()      { ! grep -rInE "(password|secret|api[_-]?key)\s*=\s*[\"'][^\"']{6,}" src/ --include='*.php'; }
queries_in_repo() { ! grep -rIn 'createQueryBuilder\|createQuery(' src/ --include='*.php' | grep -v '^src/Repository/' | grep .; }

while IFS= read -r B; do
  [ -z "$B" ] && continue
  NAME="$(inst_name "$B")"; [ -n "$TARGET" ] && [ "$NAME" != "$TARGET" ] && continue
  echo "═══ GATE BACKEND · $NAME"
  cd "$B" || continue
  FAIL=0
  run "Sintaxis PHP (archivos tocados)"      bloquea lint_php
  run "Mapeo Doctrine y esquema en sync"     bloquea php bin/console doctrine:schema:validate
  run "Contenedor Symfony"                   bloquea php bin/console lint:container
  run "Migraciones aplicadas"                bloquea php bin/console doctrine:migrations:up-to-date
  run "Sin secretos en src/"                 bloquea no_secrets
  run "Consultas solo en src/Repository/"    avisa   queries_in_repo
  [ "$FAIL" -eq 0 ] && echo "  → $NAME: VERDE" || { echo "  → $NAME: ROJO"; TOTAL=1; }
done <<< "$BACKENDS"

[ "$TOTAL" -eq 0 ] && echo "GATE BACKEND: VERDE" || echo "GATE BACKEND: ROJO"
exit "$TOTAL"
