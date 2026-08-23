#!/usr/bin/env bash
# Genera .codex/prompts/ a partir de los comandos y agentes del kit.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/.codex/prompts"
mkdir -p "$OUT"

for f in "$ROOT/.claude/commands/"*.md; do
  name="$(basename "$f" .md)"
  {
    echo "# /$name"
    echo
    sed '1{/^---$/!q}; 1,/^---$/d' "$f"
  } > "$OUT/$name.md"
done

for f in "$ROOT/.claude/agents/"*.md; do
  name="$(basename "$f" .md)"
  {
    echo "# Rol: $name"
    echo
    echo "Adopta este rol íntegramente. Antes de actuar, lee docs/state.yaml y la tarea asignada."
    echo
    sed '1{/^---$/!q}; 1,/^---$/d' "$f"
  } > "$OUT/rol-$name.md"
done

cp "$ROOT/AGENTS.md" "$ROOT/.codex/AGENTS.md" 2>/dev/null || true
echo "Generados $(ls -1 "$OUT" | wc -l) prompts en .codex/prompts/"
