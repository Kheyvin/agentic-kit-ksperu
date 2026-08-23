# AGENTS.md — instrucciones para harnesses no-Claude (Codex, Cursor, Aider, etc.)

Este repositorio usa el **Agentic Kit**. Los "subagentes" de Claude Code son, en el fondo,
archivos Markdown con un rol y un checklist. Cualquier harness puede usarlos leyéndolos.

## Equivalencias

| Concepto Claude Code | Archivo | Cómo lo usa Codex |
|---|---|---|
| Subagente | `.claude/agents/<rol>.md` | Pega su cuerpo como instrucción de rol al abrir la tarea |
| Skill | `.claude/skills/<nombre>/SKILL.md` | Lee el archivo cuando el tema coincide con su `description` |
| Comando slash | `.claude/commands/<cmd>.md` | Es un procedimiento: ejecútalo paso a paso |
| Hook (gate) | `.claude/scripts/*.sh` | Ejecútalo manualmente antes de dar por terminada la tarea |

## El layout no se asume

Antes de cualquier comando que dependa de rutas:

```bash
source .claude/scripts/paths.sh
echo "$LAYOUT | $BACKEND_DIR | $FRONTEND_DIR"
```

El proyecto puede ser monorepo (`api/`+`app/`), plano, de una sola capa o dos repos separados.
Nunca escribas `cd api/` a ciegas.

## Protocolo mínimo para Codex

1. Lee `docs/state.yaml` para saber en qué punto está el proyecto.
2. Abre la tarea asignada: `docs/tasks/TASK-XXX.md`. **Es autocontenida**: no necesitas más
   contexto ni historial de conversación.
3. Lee el archivo de rol indicado en el campo `agente:` de esa tarea.
4. Lee las skills listadas en el campo `skills:` de esa tarea.
5. Implementa. No toques archivos fuera de `archivos_permitidos`.
6. Ejecuta los gates listados en la tarea (`.claude/scripts/gate-*.sh`).
7. Marca los criterios de aceptación, actualiza `docs/state.yaml` y escribe la bitácora al
   final del propio archivo de tarea.

Regla de oro idéntica a Claude Code: **si no está escrito en `docs/`, no ocurrió.**
