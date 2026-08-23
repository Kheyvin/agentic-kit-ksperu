#!/usr/bin/env bash
# Detecta divergencia del contrato API. Crítico cuando backend y frontend viven
# en repositorios separados: ahí nada impide que uno cambie y el otro no se entere.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

CONTRACT="$ROOT/docs/CONTRACT.md"
LOCK="$ROOT/docs/.contract.lock"

[ -f "$CONTRACT" ] || { echo "✘ No existe docs/CONTRACT.md — el proyecto no está inicializado."; exit 1; }

HASH="$(sha256sum "$CONTRACT" | cut -c1-16)"

if [ ! -f "$LOCK" ]; then
  echo "$HASH" > "$LOCK"
  echo "Contrato registrado por primera vez: $HASH"
  echo "Commitea docs/.contract.lock. En repos separados debe ser IDÉNTICO en ambos."
  exit 0
fi

PREV="$(cat "$LOCK")"
if [ "$HASH" = "$PREV" ]; then
  echo "GATE CONTRATO: VERDE — sin cambios ($HASH)"
  exit 0
fi

echo "GATE CONTRATO: CAMBIÓ  $PREV → $HASH"
echo ""
echo "Un cambio de contrato exige, en el mismo lote:"
echo "  1. Un ADR en docs/adr/ que justifique el cambio."
echo "  2. Una tarea de backend y otra de frontend."
echo "  3. Si los repos están separados: copiar docs/CONTRACT.md y este lock al otro repo."
echo ""
echo "Cuando eso esté hecho: echo $HASH > docs/.contract.lock"
exit 1
