#!/usr/bin/env bash
# Detecta las instancias del proyecto. Se hace source desde los demás scripts.
#
# Soporta N backends y N frontends con nombres arbitrarios:
#   backend/ · frontend/ · ventas_backend/ · admin_frontend/ · o la propia raíz.
#
# Exporta:
#   ROOT           raíz del proyecto
#   BACKENDS       rutas de backend, una por línea (vacío = no hay)
#   FRONTENDS      rutas de frontend, una por línea (vacío = no hay)
#   N_BACKENDS     cuántas
#   N_FRONTENDS    cuántas
#   LAYOUT         plano | monorepo | multi-instancia | solo-backend | solo-frontend | sin-inicializar

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CFG="$ROOT/.claude/project.json"

# --- Lectura de JSON sin depender de jq (php > jq > grep) ---------------------
# $1 = expresión de ruta separada por puntos. Devuelve escalares o listas
# (una entrada por línea).
json_get() {
  local file="$1" path="$2"
  [ -f "$file" ] || return 0
  if command -v php >/dev/null 2>&1; then
    php -r '
      $d = json_decode(@file_get_contents($argv[1]), true);
      if (!is_array($d)) exit;
      foreach (explode(".", $argv[2]) as $k) {
        if (!is_array($d) || !array_key_exists($k, $d)) exit;
        $d = $d[$k];
      }
      if (is_array($d)) { foreach ($d as $v) if (is_scalar($v)) echo $v, "\n"; }
      elseif (is_scalar($d)) echo $d, "\n";
    ' "$file" "$path" 2>/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq -r --arg p "$path" 'getpath($p|split(".")) | if type=="array" then .[] else . end' \
      "$file" 2>/dev/null | grep -v '^null$'
  fi
}

# --- Qué cuenta como cada capa ------------------------------------------------
is_backend()  { [ -f "$1/composer.json" ] && [ -d "$1/src" ]; }
is_frontend() { [ -f "$1/package.json" ] && grep -q '"vue"' "$1/package.json" 2>/dev/null; }

# --- Descubrimiento -----------------------------------------------------------
# Configurado a mano en project.json, o automático recorriendo el primer nivel.
discover() {
  local kind="$1" fn="is_$1" out="" d
  local configured; configured="$(json_get "$CFG" "instancias.${kind}s")"

  if [ -n "$configured" ] && [ "$configured" != "auto" ]; then
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      [ "$d" = "." ] && d="$ROOT" || d="$ROOT/$d"
      [ -d "$d" ] && out="$out$d"$'\n'
    done <<< "$configured"
    printf '%s' "$out"
    return
  fi

  $fn "$ROOT" && out="$out$ROOT"$'\n'
  for d in "$ROOT"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    case "${d##*/}" in .*|node_modules|vendor|docs|var|public) continue ;; esac
    $fn "$d" && out="$out$d"$'\n'
  done
  printf '%s' "$out"
}

BACKENDS="$(discover backend)"
FRONTENDS="$(discover frontend)"

N_BACKENDS=$(printf '%s' "$BACKENDS"  | grep -c . || true)
N_FRONTENDS=$(printf '%s' "$FRONTENDS" | grep -c . || true)

if   [ "$N_BACKENDS" -eq 0 ] && [ "$N_FRONTENDS" -eq 0 ]; then LAYOUT="sin-inicializar"
elif [ "$N_BACKENDS" -gt 1 ] || [ "$N_FRONTENDS" -gt 1 ];  then LAYOUT="multi-instancia"
elif [ "$N_BACKENDS" -eq 0 ]; then LAYOUT="solo-frontend"
elif [ "$N_FRONTENDS" -eq 0 ]; then LAYOUT="solo-backend"
elif [ "$BACKENDS" = "$FRONTENDS" ]; then LAYOUT="plano"
else LAYOUT="monorepo"; fi

# Nombre corto de una instancia, tal y como se usa en docs/contracts/<nombre>.md
inst_name() { [ "$1" = "$ROOT" ] && echo "raiz" || echo "${1##*/}"; }

export ROOT BACKENDS FRONTENDS N_BACKENDS N_FRONTENDS LAYOUT
