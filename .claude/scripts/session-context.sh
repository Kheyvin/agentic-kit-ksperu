#!/usr/bin/env bash
# SessionStart: inyecta layout, instancias, rama y estado de tareas leídos del disco. Salida en texto plano.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh" 2>/dev/null || { LAYOUT="desconocido"; ROOT="$(pwd)"; }

names() { local out="" d; while IFS= read -r d; do [ -z "$d" ] && continue; out="$out$(inst_name "$d"), "; done <<< "$1"; echo "${out%, }"; }

CTX="Kit · layout: $LAYOUT"
[ "${N_BACKENDS:-0}"  -gt 0 ] && CTX="$CTX | backends: $(names "$BACKENDS")"
[ "${N_FRONTENDS:-0}" -gt 0 ] && CTX="$CTX | frontends: $(names "$FRONTENDS")"
CTX="$CTX | rama: $(git -C "$ROOT" branch --show-current 2>/dev/null || echo 'sin git')"
if [ -d "$ROOT/docs/tasks" ]; then
  CTX="$CTX | $(bash "$DIR/estado.sh" --resumen 2>/dev/null)"
else
  CTX="$CTX | sin docs/: proyecto no inicializado → /iniciar"
fi
[ "$LAYOUT" = "sin-inicializar" ] && [ -d "$ROOT/docs" ] && \
  CTX="$CTX | AVISO: hay docs/ pero no se detecta ninguna instancia; los gates se omiten. Revisa .claude/project.json."
printf '%s\n' "$CTX"
exit 0
