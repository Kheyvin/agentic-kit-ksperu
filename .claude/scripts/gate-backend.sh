#!/usr/bin/env bash
# Gate de backend. Recorre TODAS las instancias de backend del repositorio.
# Uso:  gate-backend.sh            → todas
#       gate-backend.sh ventas_backend → solo esa
# Rápido a propósito: sin 'composer audit' ni nada que tarde. Eso vive en deep-check.sh.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

TARGET="${1:-}"
if [ "$N_BACKENDS" -eq 0 ]; then
  echo "No hay backend en este repositorio (layout: $LAYOUT). Gate omitido."
  exit 0
fi

TOTAL=0
step()  { echo ""; echo "── $1"; }
check() { if "$@" >/dev/null 2>&1; then echo "  ✔ ok"; else echo "  ✘ FALLA"; FAIL=1; fi }
warn()  { if "$@" >/dev/null 2>&1; then echo "  ✔ ok"; else echo "  ⚠ aviso (no bloquea)"; fi }

while IFS= read -r B; do
  [ -z "$B" ] && continue
  NAME="$(inst_name "$B")"
  [ -n "$TARGET" ] && [ "$NAME" != "$TARGET" ] && continue

  echo ""; echo "═══ GATE BACKEND · $NAME  ($LAYOUT)"
  cd "$B" || continue
  FAIL=0

  step "Lint PHP de src/"
  check bash -c 'find src -name "*.php" -print0 | xargs -0 -r -n1 php -l'

  step "Mapeo Doctrine válido"
  check php bin/console doctrine:schema:validate --skip-sync

  step "Contenedor Symfony sin errores"
  check php bin/console lint:container

  step "YAML de configuración"
  check php bin/console lint:yaml config

  step "Migraciones aplicadas"
  check php bin/console doctrine:migrations:up-to-date

  step "Sin secretos hardcodeados en src/"
  check bash -c '! grep -rInE "(password|secret|api[_-]?key)\s*=\s*[\"'\''][^\"'\'']{6,}" src/ --include="*.php"'

  step "Sin QueryBuilder fuera de Repository/"
  check bash -c '! grep -rIn "createQueryBuilder\|createQuery(" src/ --include="*.php" | grep -v "^src/Repository/"'

  step "Base de datos en SQLite (estándar de desarrollo del kit)"
  warn bash -c 'grep -qE "^DATABASE_URL=.?sqlite:" .env'

  echo ""
  [ "$FAIL" -eq 0 ] && echo "  → $NAME: VERDE" || { echo "  → $NAME: ROJO"; TOTAL=1; }
done <<< "$BACKENDS"

echo ""
[ "$TOTAL" -eq 0 ] && echo "GATE BACKEND: VERDE" || echo "GATE BACKEND: ROJO"
exit "$TOTAL"
