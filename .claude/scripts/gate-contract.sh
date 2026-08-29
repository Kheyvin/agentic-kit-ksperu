#!/usr/bin/env bash
# Detecta divergencia del contrato API. Un contrato POR INSTANCIA de backend:
#   docs/contracts/<instancia>.md   +   docs/contracts/<instancia>.lock
# Con varios backends, cada uno tiene el suyo y se vigilan por separado.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"

CDIR="$ROOT/docs/contracts"
FAIL=0
FOUND=0

verify() {  # $1 = nombre de instancia
  local name="$1" file="$CDIR/$1.md" lock="$CDIR/$1.lock" hash prev
  FOUND=1
  if [ ! -f "$file" ]; then
    echo "✘ $name — falta docs/contracts/$name.md. Sin contrato, el cliente adivina."
    FAIL=1; return
  fi
  hash="$(sha256sum "$file" | cut -c1-16)"
  if [ ! -f "$lock" ]; then
    echo "$hash" > "$lock"
    echo "· $name — contrato registrado por primera vez: $hash"
    return
  fi
  prev="$(cat "$lock")"
  if [ "$hash" = "$prev" ]; then
    echo "✔ $name — sin cambios ($hash)"
    return
  fi
  echo "✘ $name — EL CONTRATO CAMBIÓ  $prev → $hash"
  echo "    Un cambio de contrato exige, en el mismo lote:"
  echo "      1. Un ADR en docs/adr/ que lo justifique."
  echo "      2. Una tarea de backend y otra de frontend para $name."
  echo "    Cuando esté hecho:  echo $hash > docs/contracts/$name.lock"
  FAIL=1
}

mkdir -p "$CDIR"

if [ "$N_BACKENDS" -gt 0 ]; then
  while IFS= read -r B; do
    [ -z "$B" ] && continue
    verify "$(inst_name "$B")"
  done <<< "$BACKENDS"
else
  # Sin backend en este repositorio: se vigilan igualmente los contratos que
  # haya declarados, porque el frontend los consume de alguien.
  for f in "$CDIR"/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .md)"; verify "$n"
  done
fi

if [ "$FOUND" -eq 0 ]; then
  echo "✘ No hay ningún contrato en docs/contracts/. El proyecto no está inicializado."
  exit 1
fi

echo ""
[ "$FAIL" -eq 0 ] && echo "GATE CONTRATO: VERDE" || echo "GATE CONTRATO: ROJO"
exit "$FAIL"
