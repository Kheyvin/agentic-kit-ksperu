---
description: Muestra el estado real del proyecto leyéndolo de docs/, no de la memoria
---

**No respondas de memoria.** Lee del disco y reporta lo que encuentres:

1. `docs/state.yaml` — fase, historias y tareas por estado.
2. `git status` y `git log --oneline -10`.
3. Últimos archivos en `docs/audits/` y su veredicto.
4. Tareas `bloqueada` y el motivo escrito en cada una.

Reporta en este orden y con esta forma:

- **Fase actual** y qué falta para cerrarla.
- **En curso**: tarea, agente, desde cuándo.
- **Bloqueado**: qué y por qué (esto va primero si hay algo).
- **Siguiente acción recomendada**, con el comando concreto.
- **Deuda anotada**, si la hay.

Si `docs/state.yaml` no existe, dilo claramente y propón `/init-project`. Si el estado en disco
contradice lo que se dijo en el chat, **gana el disco** y señala la discrepancia.
