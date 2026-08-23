# Usar este kit con Codex (u otro harness)

El kit está escrito en Markdown plano a propósito: los "subagentes" y las "skills" de Claude
Code son archivos de rol y de estándar, no un formato propietario. Cualquier herramienta que
sepa leer archivos puede usarlos.

## Puesta en marcha

1. Copia `AGENTS.md` a la raíz del repositorio (Codex lo lee automáticamente).
2. Ejecuta `bash .claude/codex/sync-codex.sh` para generar `.codex/prompts/` con un prompt por
   comando del kit.
3. Trabaja siempre por tarea: abre `docs/tasks/TASK-XXX.md` y pásale a Codex el rol indicado en
   el campo `agente:`.

## Diferencias reales

| Función | Claude Code | Codex |
|---|---|---|
| Delegación entre agentes | Automática (subagentes) | Manual: una sesión por rol |
| Carga de skills | Automática por `description` | Manual: pega o referencia el SKILL.md |
| Gates | Hooks, se ejecutan solos | Manual: corre `.claude/scripts/gate-*.sh` |
| Estado | `docs/state.yaml` | `docs/state.yaml` — **idéntico** |

La pieza que hace esto portable es que **nada vive en el harness**: el contrato, las historias,
las tareas y el estado están en `docs/`, versionados. Cambiar de herramienta no pierde nada.

## Flujo manual equivalente

```bash
# 1. Ver dónde estás
cat docs/state.yaml

# 2. Abrir la tarea y su rol
cat docs/tasks/TASK-014.md
cat .claude/agents/backend-developer.md     # ← pégalo como instrucción de sistema
cat .claude/skills/backend-symfony/SKILL.md # ← y la skill que pide la tarea

# 3. Implementar, y luego el gate a mano
bash .claude/scripts/gate-backend.sh

# 4. Auditar con otra sesión limpia
cat .claude/agents/code-auditor.md
git diff
```

Correr la auditoría en una **sesión distinta** de la que escribió el código no es un detalle:
un modelo que acaba de escribir algo tiende a defenderlo. El contexto limpio es la mitad del
valor de la auditoría.
