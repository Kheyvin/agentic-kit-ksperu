#!/usr/bin/env bash
# PostToolUse: formatea el archivo recién escrito. Independiente del layout. Nunca bloquea.
set -uo pipefail
INPUT="$(cat)"
FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

# Sube desde el archivo hasta encontrar la raíz del paquete que lo contiene.
pkg_root() {
  local d; d="$(cd "$(dirname "$1")" && pwd)"
  while [ "$d" != "/" ]; do
    [ -f "$d/$2" ] && { echo "$d"; return; }
    d="$(dirname "$d")"
  done
}

case "$FILE" in
  *.php)
    php -l "$FILE" >/dev/null 2>&1 || { echo "Sintaxis PHP inválida en $FILE" >&2; exit 2; }
    R="$(pkg_root "$FILE" composer.json)"
    [ -n "$R" ] && [ -x "$R/vendor/bin/php-cs-fixer" ] && \
      (cd "$R" && vendor/bin/php-cs-fixer fix "$FILE" --quiet >/dev/null 2>&1)
    ;;
  *.vue|*.js|*.mjs|*.css|*.json)
    R="$(pkg_root "$FILE" package.json)"
    [ -n "$R" ] && [ -x "$R/node_modules/.bin/prettier" ] && \
      (cd "$R" && node_modules/.bin/prettier --write "$FILE" >/dev/null 2>&1)
    ;;
esac
exit 0
