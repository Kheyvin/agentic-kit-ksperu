#!/usr/bin/env bash
# PreToolUse(Bash): bloquea comandos destructivos. exit 2 = bloquear.
set -uo pipefail
CMD="$(cat | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -z "$CMD" ] && exit 0

block() { echo "GATE BLOQUEADO: $1" >&2; exit 2; }

case "$CMD" in
  *"doctrine:schema:update"*)  block "schema:update está prohibido. Usa make:migration + migrations:migrate." ;;
  *"doctrine:database:drop"*)  block "drop de base de datos requiere confirmación humana explícita." ;;
  *"git push --force"*)        block "force push prohibido." ;;
  *"rm -rf /"*)                block "borrado peligroso." ;;
  *".env.local"*)              block "no se manipulan secretos desde el agente." ;;
  *"config/jwt"*)              block "las claves JWT no se tocan desde el agente." ;;
esac
exit 0
