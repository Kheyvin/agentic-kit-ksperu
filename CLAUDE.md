# Instrucciones del proyecto

Este proyecto usa el **Agentic Kit**: un equipo de subagentes con roles definidos.
No improvises el proceso — sigue el protocolo.

## Reglas duras

1. **Nunca escribas código sin una tarea.** Si no existe `docs/tasks/TASK-XXX.md` para lo que
   se pide, invoca al `orchestrator` para que la cree primero.
2. **El estado vive en disco, no en el chat.** Antes de responder cualquier "¿cómo vamos?",
   lee `docs/state.yaml`. Después de cualquier cambio de estado, escríbelo ahí.
3. **El contrato API manda.** `docs/CONTRACT.md` es la fuente de verdad compartida entre
   backend y frontend. Cambiarlo requiere ADR y actualizar ambos lados en la misma tarea.
4. **Delegación obligatoria.** Backend → `backend-developer`. Frontend → `frontend-developer`.
   Revisión → `code-auditor`. No hagas tú el trabajo de un especialista.
5. **Ningún trabajo se cierra sin gate en verde.** Ver `.claude/skills/task-spec/SKILL.md`.
6. **Español** en documentación, historias, ADRs y comentarios. Código y nombres en inglés.
7. **No asumas la estructura del proyecto.** El layout varía: ejecuta
   `source .claude/scripts/paths.sh` y usa `$BACKEND_DIR` y `$FRONTEND_DIR`. Nunca escribas
   `cd api/` a ciegas.
8. **No propongas CI ni infraestructura de despliegue** mientras `infra.ci` e `infra.deploy`
   sigan sin decidir en `docs/state.yaml`. Los gates ya corren por hook en local.

## Árbol de documentación (lo crea `/init-project`)

```
docs/
├── state.yaml              # índice único de historias y tareas — la "memoria"
├── BRIEF.md                # qué se está construyendo y para quién
├── CONTRACT.md             # contrato API compartido (fuente de verdad)
├── adr/ADR-XXX-*.md        # decisiones de arquitectura
├── stories/STORY-XXX.yaml  # historias de usuario + criterios Gherkin
├── tasks/TASK-XXX.md       # unidades de trabajo autocontenidas
├── mockups/*.html          # bocetos HTML estáticos, previos al código Vue
├── audits/AUDIT-XXX.md     # hallazgos de auditoría
└── qa/                     # specs Playwright y reportes
```

## Layouts soportados

`monorepo` (`api/` + `app/`) · `plano` (ambos en la raíz) · `solo-backend` · `solo-frontend` ·
`repos-separados` (mismo `.claude/` y `docs/` copiados en los dos, con `gate-contract.sh`
vigilando que el contrato no diverja).

Los gates se adaptan solos: si una capa no está en este repositorio, su gate se omite en vez
de fallar.

## Arranque de sesión

Al iniciar, lee `docs/state.yaml` y resume en 3 líneas: fase actual, tareas en curso,
bloqueos. Si el archivo no existe, propón `/init-project`.
