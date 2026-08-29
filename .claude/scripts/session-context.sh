#!/usr/bin/env bash
# SessionStart: inyecta layout, instancias y estado real, para no depender de la
# memoria del chat.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh" 2>/dev/null || LAYOUT="desconocido"

CTX="Layout: ${LAYOUT}"

names() { local out="" d; while IFS= read -r d; do [ -z "$d" ] && continue
  out="$out$(inst_name "$d"), "; done <<< "$1"; echo "${out%, }"; }

[ "${N_BACKENDS:-0}"  -gt 0 ] && CTX="$CTX | backends: $(names "$BACKENDS")"
[ "${N_FRONTENDS:-0}" -gt 0 ] && CTX="$CTX | frontends: $(names "$FRONTENDS")"
CTX="$CTX | Rama: $(git branch --show-current 2>/dev/null || echo 'sin git')"

if [ -f "$ROOT/docs/state.yaml" ]; then
  N=$(grep -c 'estado: en_curso'  "$ROOT/docs/state.yaml" 2>/dev/null || echo 0)
  B=$(grep -c 'estado: bloqueada' "$ROOT/docs/state.yaml" 2>/dev/null || echo 0)
  CTX="$CTX | En curso: $N, bloqueadas: $B | Lee docs/state.yaml antes de actuar."
else
  CTX="$CTX | Sin docs/state.yaml: proyecto no inicializado. Sugiere /iniciar-proyecto."
fi

printf '%s' "$CTX" | php -r 'echo json_encode(["additionalContext"=>stream_get_contents(STDIN)]), "\n";'
exit 0
