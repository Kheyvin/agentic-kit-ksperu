---
description: Ejecuta una tarea despachándola al agente especialista correspondiente
argument-hint: "TASK-014"
---

Ejecuta la tarea: $ARGUMENTS

Procedimiento del orquestador:

1. Lee `docs/tasks/$ARGUMENTS.md`. Si no existe, dilo y para.
2. Verifica `depende_de`: si alguna dependencia no está `hecha`, no arranques.
3. Comprueba que la tarea declara `instancia:`. Si hay más de un backend o frontend y no lo dice,
   la tarea no es autocontenida: arréglala antes de despacharla.
4. Si es una tarea de frontend sin mockup existente, invoca antes a `ux-prototyper`.
5. Marca la tarea `en_curso` en `docs/state.yaml`.
6. Invoca al subagente del campo `agente:` con **una sola instrucción**:
   "Ejecuta `docs/tasks/$ARGUMENTS.md`". No le resumas contexto.
7. Al volver, invoca a `code-auditor` sobre el diff. Si la tarea toca autenticación, permisos
   o datos personales, invoca también a `security-reviewer`.
8. Veredicto RECHAZADO → la tarea vuelve a `en_curso` con los hallazgos; se reintenta una vez.
   Si vuelve a fallar, queda `bloqueada` y se consulta al humano.
9. Veredicto aprobado → `hecha`, actualiza `docs/state.yaml` y propón la siguiente tarea
   desbloqueada.

El gate de la tarea puede acotarse a su instancia:
`bash .claude/scripts/gate-backend.sh ventas_backend`.
