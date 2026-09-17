#!/usr/bin/env bash
# Detecta las instancias del proyecto. Se hace source desde los demás scripts.
# Soporta N backends y N frontends: backend/ · frontend/ · ventas_backend/ · admin_frontend/ · o la raíz.
#
# Exporta:
#   ROOT         raíz del proyecto (ruta POSIX)
#   BACKENDS     rutas de backend, una por línea (vacío = no hay)
#   FRONTENDS    rutas de frontend, una por línea
#   N_BACKENDS · N_FRONTENDS
#   LAYOUT       plano | monorepo | multi-instancia | solo-backend | solo-frontend | sin-inicializar
# Funciones: inst_name <ruta> → nombre corto · inst_path <nombre> → ruta

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$ROOT" in
  [A-Za-z]:\\*|[A-Za-z]:/*) command -v cygpath >/dev/null 2>&1 && ROOT="$(cygpath -u "$ROOT")" ;;
esac
ROOT="${ROOT%/}"
CFG="$ROOT/.claude/project.json"

# Lee instancias.<backends|frontends> de project.json: "auto" o lista. Sin jq: php o node.
json_list() {
  [ -f "$CFG" ] || return 0
  if command -v php >/dev/null 2>&1; then
    php -r '$d=json_decode(@file_get_contents($argv[1]),true);$v=$d["instancias"][$argv[2]]??null;
      if(is_array($v)){foreach($v as $x)echo $x,"\n";}elseif(is_string($v))echo $v,"\n";' "$CFG" "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));const v=(d.instancias||{})[process.argv[2]];
      if(Array.isArray(v))v.forEach(x=>console.log(x));else if(typeof v==="string")console.log(v);' "$CFG" "$1" 2>/dev/null
  fi
}

is_backend()  { [ -f "$1/composer.json" ] && [ -d "$1/src" ]; }
is_frontend() { [ -f "$1/package.json" ] && grep -q '"vue"' "$1/package.json" 2>/dev/null; }

discover() {  # $1 = backend | frontend
  local fn="is_$1" out="" d cfg
  cfg="$(json_list "${1}s")"
  if [ -n "$cfg" ] && [ "$cfg" != "auto" ]; then
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      [ "$d" = "." ] && d="$ROOT" || d="$ROOT/$d"
      [ -d "$d" ] && out="$out$d"$'\n'
    done <<< "$cfg"
    printf '%s' "$out"; return
  fi
  $fn "$ROOT" && out="$out$ROOT"$'\n'
  for d in "$ROOT"/*/; do
    d="${d%/}"; [ -d "$d" ] || continue
    case "${d##*/}" in .*|node_modules|vendor|docs|var|public|dist|tests) continue ;; esac
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

inst_name() { [ "$1" = "$ROOT" ] && echo "raiz" || echo "${1##*/}"; }
inst_path() {
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && [ "$(inst_name "$d")" = "$1" ] && { echo "$d"; return 0; }
  done <<< "$BACKENDS"$'\n'"$FRONTENDS"
  return 1
}

export ROOT BACKENDS FRONTENDS N_BACKENDS N_FRONTENDS LAYOUT
