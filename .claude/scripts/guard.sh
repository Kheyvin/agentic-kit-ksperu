#!/usr/bin/env bash
# PreToolUse(Bash|Write|Edit): bloquea lo destructivo y lo que salta el proceso. exit 2 = bloquear.
# Sin jq: el JSON se lee con php o node; si no hay ninguno, se inspecciona la carga cruda.
set -uo pipefail
INPUT="$(cat)"

field() {  # $1 = ruta.con.puntos → valor escalar
  if command -v php >/dev/null 2>&1; then
    printf '%s' "$INPUT" | php -r '$d=json_decode(stream_get_contents(STDIN),true);
      foreach(explode(".",$argv[1]) as $k){ if(!is_array($d)||!array_key_exists($k,$d)) exit; $d=$d[$k]; }
      if(is_scalar($d)) echo $d;' "$1" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$INPUT" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{try{let o=JSON.parse(s);
      for(const k of process.argv[1].split(".")){if(o===null||typeof o!=="object"||!(k in o))return;o=o[k];}
      if(o!==null&&typeof o!=="object")process.stdout.write(String(o));}catch(e){}})' "$1" 2>/dev/null
  fi
}
block() { echo "BLOQUEADO POR EL GUARD: $1" >&2; exit 2; }

TOOL="$(field tool_name)"

if [ -z "$TOOL" ]; then  # JSON ilegible: no se falla abierto ante patrones destructivos
  case "$INPUT" in
    *doctrine:schema:update*|*doctrine:database:drop*|*"git push --force"*|*"git push -f"*|*"rm -rf /"*)
      block "carga del hook ilegible con un patrón destructivo. Revísalo a mano." ;;
  esac
  exit 0
fi

if [ "$TOOL" = "Bash" ]; then
  CMD="$(field tool_input.command)"
  case "$CMD" in
    *bin/console*doctrine:schema:update*)   block "schema:update no se ejecuta. Flujo: make:migration → leer el SQL → doctrine:migrations:migrate." ;;
    *bin/console*doctrine:database:drop*)   block "borrar la base de datos lo hace el usuario a mano, no el agente." ;;
    *"git push --force"*|*"git push -f"*)   block "force push prohibido." ;;
    *"rm -rf /"*|*"rm -rf ~"*)              block "borrado peligroso." ;;
    *.env.local*)                           block "los secretos (.env.local) no se leen ni se escriben desde el agente." ;;
    *config/jwt*)                           block "las claves JWT no se tocan a mano. Se generan con lexik:jwt:generate-keypair." ;;
  esac
  exit 0
fi

if [ "$TOOL" = "Write" ] || [ "$TOOL" = "Edit" ]; then
  FILE="$(field tool_input.file_path | tr '\\' '/')"
  case "$FILE" in
    */migrations/Version*.php) block "las migraciones se generan con make:migration y no se editan. Si está mal, corrige la entidad y genera otra." ;;
    *.env.local|*/config/jwt/*) block "secretos y claves JWT no se escriben desde el agente." ;;
  esac
fi
exit 0
