#!/usr/bin/env bash
# Detecta el layout del proyecto. Se hace source desde los demás scripts.
# Soporta: monorepo (api/ + app/), plano (Symfony y Vite en la raíz),
# solo-backend, solo-frontend y repos separados.
#
# Exporta: LAYOUT, BACKEND_DIR, FRONTEND_DIR  (vacío = esa capa no está aquí)

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CFG="$ROOT/.claude/project.json"

read_cfg() {  # $1 = clave
  [ -f "$CFG" ] || { echo "auto"; return; }
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$1" '.[$k] // "auto"' "$CFG"
  else
    grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$CFG" | sed 's/.*"\([^"]*\)"$/\1/' || echo auto
  fi
}

is_backend()  { [ -f "$1/composer.json" ] && [ -d "$1/src" ]; }
is_frontend() { [ -f "$1/package.json" ] && grep -q '"vue"' "$1/package.json" 2>/dev/null; }

BACKEND_DIR="$(read_cfg backend_dir)"
FRONTEND_DIR="$(read_cfg frontend_dir)"

if [ "$BACKEND_DIR" = "auto" ] || [ -z "$BACKEND_DIR" ]; then
  BACKEND_DIR=""
  for c in "$ROOT" "$ROOT/api" "$ROOT/backend" "$ROOT/server"; do
    if is_backend "$c"; then BACKEND_DIR="$c"; break; fi
  done
else
  BACKEND_DIR="$ROOT/$BACKEND_DIR"
fi

if [ "$FRONTEND_DIR" = "auto" ] || [ -z "$FRONTEND_DIR" ]; then
  FRONTEND_DIR=""
  for c in "$ROOT" "$ROOT/app" "$ROOT/frontend" "$ROOT/client" "$ROOT/web"; do
    if is_frontend "$c"; then FRONTEND_DIR="$c"; break; fi
  done
else
  FRONTEND_DIR="$ROOT/$FRONTEND_DIR"
fi

if   [ -n "$BACKEND_DIR" ] && [ -n "$FRONTEND_DIR" ] && [ "$BACKEND_DIR" = "$FRONTEND_DIR" ]; then LAYOUT="plano"
elif [ -n "$BACKEND_DIR" ] && [ -n "$FRONTEND_DIR" ]; then LAYOUT="monorepo"
elif [ -n "$BACKEND_DIR" ]; then LAYOUT="solo-backend"
elif [ -n "$FRONTEND_DIR" ]; then LAYOUT="solo-frontend"
else LAYOUT="sin-inicializar"; fi

export ROOT LAYOUT BACKEND_DIR FRONTEND_DIR
