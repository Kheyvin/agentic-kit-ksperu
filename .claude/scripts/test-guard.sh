#!/usr/bin/env bash
# Suite del guard. Los payloads los serializa PHP con json_encode para que el
# escapado (rutas Windows incluidas) sea el real que envia el harness.
G="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard.sh"; pass=0; fail=0
mk(){ php -r 'echo json_encode(["tool_name"=>$argv[1],"tool_input"=>[$argv[2]=>$argv[3]]]);' "$1" "$2" "$3"; }
t(){ printf '%s' "$2" | bash "$G" >/dev/null 2>&1; got=$?
  if [ "$got" = "$3" ]; then pass=$((pass+1)); r="OK   "; else fail=$((fail+1)); r="FALLA"; fi
  printf '%s %-32s esperado=%s obtenido=%s\n' "$r" "$1" "$3" "$got"; }
D="doctrine:database:drop"; U="doctrine:schema:update"; P="git push --force"; E=".env.local"; J="config/jwt"
t "drop de BD"            "$(mk Bash command "php bin/console $D --force")" 2
t "schema update"         "$(mk Bash command "php bin/console $U --force")" 2
t "force push"            "$(mk Bash command "$P origin main")" 2
t "leer secreto"          "$(mk Bash command "cat $E")" 2
t "tocar claves jwt"      "$(mk Bash command "ls $J")" 2
t "make:migration"        "$(mk Bash command 'php bin/console make:migration')" 0
t "generar keypair"       "$(mk Bash command 'php bin/console lexik:jwt:generate-keypair')" 0
t "npm install"           "$(mk Bash command 'npm install axios')" 0
t "symfony new"           "$(mk Bash command 'symfony new backend --version=8.1.*')" 0
t "crear entidad unix"    "$(mk Write file_path '/c/proj/backend/src/Entity/Product.php')" 2
t "crear entidad Windows" "$(mk Write file_path 'C:\proj\backend\src\Entity\Order.php')" 2
t "escribir migracion"    "$(mk Write file_path '/c/proj/backend/migrations/Version20260101.php')" 2
t "editar README"         "$(mk Edit file_path "$PWD/README.md")" 0
t "editar entidad existente" "$(mk Edit file_path "$PWD/.claude/scripts/paths.sh")" 0
t "json roto + destructivo"  "{roto $D" 2
t "json roto inocuo"         "{roto npm run dev" 0
echo "---- $pass ok, $fail fallos"; exit $fail
