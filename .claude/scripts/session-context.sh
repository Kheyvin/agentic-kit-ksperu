#!/usr/bin/env bash
# SessionStart: inyecta layout y estado real, para no depender de la memoria del chat.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh" 2>/dev/null || LAYOUT="desconocido"

CTX="Layout: ${LAYOUT}"
[ -n "${BACKEND_DIR:-}" ]  && CTX="$CTX | backend: ${BACKEND_DIR#$ROOT/}"
[ -n "${FRONTEND_DIR:-}" ] && CTX="$CTX | frontend: ${FRONTEND_DIR#$ROOT/}"
CTX="$CTX | Rama: $(git branch --show-current 2>/dev/null || echo 'sin git')"

if [ -f "$ROOT/docs/state.yaml" ]; then
  N=$(grep -c 'estado: en_curso' "$ROOT/docs/state.yaml" 2>/dev/null || echo 0)
  B=$(grep -c 'estado: bloqueada' "$ROOT/docs/state.yaml" 2>/dev/null || echo 0)
  CTX="$CTX | En curso: $N, bloqueadas: $B | Lee docs/state.yaml antes de actuar."
else
  CTX="$CTX | Sin docs/state.yaml: proyecto no inicializado. Sugiere /init-project."
fi
printf '{"additionalContext": "%s"}\n' "$CTX"
exit 0
