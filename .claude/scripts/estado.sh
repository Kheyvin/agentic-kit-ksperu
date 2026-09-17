#!/usr/bin/env bash
# Estado del proyecto, leído del frontmatter de docs/tasks/TASK-*.md. No hay otro registro.
# Uso:
#   estado.sh                               tabla de tareas, bloqueos y siguiente
#   estado.sh --resumen                     una línea (la usa el hook de sesión)
#   estado.sh --siguiente                   id de la primera pendiente con dependencias hechas
#   estado.sh --marcar ID ESTADO [MOTIVO]   cambia estado (pendiente|en_curso|bloqueada|hecha); MOTIVO rellena bloqueo:
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/paths.sh"
TDIR="$ROOT/docs/tasks"
MODE="${1:-}"

fm() {  # $1 archivo, $2 clave → valor del frontmatter (sin comentario ni espacios sobrantes)
  awk -v k="$2" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    /^---/ { exit }
    index($0, k ":") == 1 { v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v); print v; exit }
  ' "$1"
}

if [ "$MODE" = "--marcar" ]; then
  ID="${2:-}"; ST="${3:-}"; MOTIVO="${4:-}"; F="$TDIR/$ID.md"
  [ -f "$F" ] || { echo "No existe $F" >&2; exit 1; }
  case "$ST" in pendiente|en_curso|bloqueada|hecha) ;; *) echo "Estado inválido: $ST (pendiente|en_curso|bloqueada|hecha)" >&2; exit 1 ;; esac
  sed -i "0,/^estado:.*/s//estado: $ST/" "$F"
  if [ -n "$MOTIVO" ]; then
    M="$(printf '%s' "$MOTIVO" | sed 's/[&/\]/\\&/g')"
    if grep -q '^bloqueo:' "$F"; then sed -i "0,/^bloqueo:.*/s//bloqueo: $M/" "$F"
    else sed -i "0,/^estado:.*/s//&\nbloqueo: $M/" "$F"; fi
  elif [ "$ST" != "bloqueada" ] && grep -q '^bloqueo:' "$F"; then
    sed -i '/^bloqueo:/d' "$F"
  fi
  echo "$ID → $ST${MOTIVO:+ ($MOTIVO)}"
  exit 0
fi

if [ ! -d "$TDIR" ]; then
  [ "$MODE" = "--resumen" ] && echo "sin docs/tasks (proyecto sin planificar)" || echo "No hay docs/tasks/. Usa /iniciar y después /planificar."
  exit 0
fi

IDS=(); declare -A EST TIT AG INS DEP BLQ REV
for f in "$TDIR"/TASK-*.md; do
  [ -e "$f" ] || continue
  id="$(fm "$f" id)"; [ -z "$id" ] && id="$(basename "$f" .md)"
  IDS+=("$id")
  EST[$id]="$(fm "$f" estado)"; TIT[$id]="$(fm "$f" titulo)"; AG[$id]="$(fm "$f" agente)"; INS[$id]="$(fm "$f" instancia)"
  DEP[$id]="$(fm "$f" depende_de | tr -d '[]' | tr ',' ' ')"; BLQ[$id]="$(fm "$f" bloqueo)"; REV[$id]="$(fm "$f" revision)"
done

count() { local id n=0; for id in "${IDS[@]}"; do [ "${EST[$id]}" = "$1" ] && n=$((n+1)); done; echo "$n"; }
siguiente() {
  local id d ok
  for id in "${IDS[@]}"; do
    [ "${EST[$id]}" = "pendiente" ] || continue
    ok=1; for d in ${DEP[$id]}; do [ "${EST[$d]:-}" = "hecha" ] || { ok=0; break; }; done
    [ "$ok" -eq 1 ] && { echo "$id"; return 0; }
  done
  return 1
}

case "$MODE" in
  --siguiente) siguiente || { echo "ninguna (no hay pendientes con las dependencias hechas)"; exit 1; } ;;
  --resumen)
    echo "tareas: $(count hecha) hechas · $(count en_curso) en curso · $(count pendiente) pendientes · $(count bloqueada) bloqueadas | siguiente: $(siguiente || echo ninguna)" ;;
  *)
    [ "${#IDS[@]}" -eq 0 ] && { echo "docs/tasks/ está vacío. Usa /planificar."; exit 0; }
    printf '%-10s %-10s %-13s %-16s %-4s %s\n' ID ESTADO AGENTE INSTANCIA REV TITULO
    for id in "${IDS[@]}"; do
      printf '%-10s %-10s %-13s %-16s %-4s %s\n' "$id" "${EST[$id]}" "${AG[$id]}" "${INS[$id]}" "${REV[$id]}" "${TIT[$id]}"
    done
    echo
    for id in "${IDS[@]}"; do [ "${EST[$id]}" = "bloqueada" ] && echo "BLOQUEADA  $id — ${BLQ[$id]:-motivo en la bitácora}"; done
    for id in "${IDS[@]}"; do [ "${EST[$id]}" = "en_curso" ]  && echo "EN CURSO   $id — ${TIT[$id]}"; done
    echo "Siguiente: $(siguiente || echo ninguna)"
    ;;
esac
exit 0
