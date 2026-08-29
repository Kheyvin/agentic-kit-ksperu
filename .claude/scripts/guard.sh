#!/usr/bin/env bash
# PreToolUse(Bash|Write|Edit): bloquea acciones destructivas o que saltan el proceso.
# exit 2 = bloquear. Sin dependencia de jq: parsea el JSON con PHP.
set -uo pipefail
INPUT="$(cat)"

field() {
  printf '%s' "$INPUT" | php -r '
    $d = json_decode(stream_get_contents(STDIN), true);
    if (!is_array($d)) exit;
    foreach (explode(".", $argv[1]) as $k) {
      if (!is_array($d) || !array_key_exists($k, $d)) exit;
      $d = $d[$k];
    }
    if (is_scalar($d)) echo $d;
  ' "$1" 2>/dev/null
}

block() { echo "GATE BLOQUEADO: $1" >&2; exit 2; }

TOOL="$(field tool_name)"

# Respaldo: si el JSON no se puede parsear, no se falla abierto. Se inspecciona
# la carga cruda en busca de patrones destructivos antes de dejar pasar nada.
if [ -z "$TOOL" ]; then
  case "$INPUT" in
    *"doctrine:schema:update"*|*"doctrine:database:drop"*|*"git push --force"*|*"rm -rf /"*)
      block "carga del hook ilegible y contiene un patron destructivo. Revisalo a mano." ;;
  esac
  exit 0
fi

# ---------------------------------------------------------------- Bash --------
if [ "$TOOL" = "Bash" ]; then
  CMD="$(field tool_input.command)"
  [ -z "$CMD" ] && exit 0
  case "$CMD" in
    *bin/console*"doctrine:schema:update"*) block "schema:update está prohibido. Usa make:migration + doctrine:migrations:migrate." ;;
    *bin/console*"doctrine:database:drop"*) block "drop de base de datos requiere confirmación humana explícita." ;;
    *"git push --force"*)       block "force push prohibido." ;;
    *"rm -rf /"*)               block "borrado peligroso." ;;
    *".env.local"*)             block "no se manipulan secretos desde el agente." ;;
    *"config/jwt"*)             block "las claves JWT no se tocan a mano. Usa lexik:jwt:generate-keypair." ;;
  esac
  exit 0
fi

# ------------------------------------------------------- Write | Edit ---------
# Las entidades y las migraciones se GENERAN con comandos, nunca se escriben a mano.
# Editar una entidad ya existente sí se permite: es donde se añaden los atributos
# de API Platform y los grupos de serialización.
if [ "$TOOL" = "Write" ] || [ "$TOOL" = "Edit" ]; then
  FILE="$(field tool_input.file_path)"
  [ -z "$FILE" ] && exit 0
  NORM="$(printf '%s' "$FILE" | tr '\' '/')"

  case "$NORM" in
    */migrations/Version*.php)
      block "las migraciones las genera 'php bin/console make:migration'. No se escriben ni se editan a mano; si está mal, se crea una nueva." ;;
  esac

  case "$NORM" in
    */src/Entity/*.php)
      if [ ! -f "$FILE" ]; then
        block "no se crean entidades a mano. Usa: php bin/console make:entity <Nombre> (ver skill db-migrations para pasarle las respuestas por stdin)."
      fi ;;
  esac
fi
exit 0
