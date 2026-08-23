#!/usr/bin/env bash
# Gate de backend. Funciona con cualquier layout. != 0 si algo no pasa.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

if [ -z "$BACKEND_DIR" ]; then
  echo "No hay backend en este repositorio (layout: $LAYOUT). Gate omitido."
  exit 0
fi
cd "$BACKEND_DIR"
echo "Gate backend en: $BACKEND_DIR  (layout: $LAYOUT)"

FAIL=0
step()  { echo ""; echo "── $1"; }
check() { if "$@" >/dev/null 2>&1; then echo "  ✔ ok"; else echo "  ✘ FALLA"; FAIL=1; fi }

step "Lint PHP de src/"
check bash -c 'find src -name "*.php" -print0 | xargs -0 -n1 php -l'

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

step "Dependencias sin CVE conocidos"
check composer audit --no-interaction

echo ""
[ "$FAIL" -eq 0 ] && echo "GATE BACKEND: VERDE" || echo "GATE BACKEND: ROJO"
exit "$FAIL"
