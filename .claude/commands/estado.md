---
description: Muestra el estado real del proyecto leyéndolo de docs/, no de la memoria
---

**No respondas de memoria.** Lee del disco y reporta lo que encuentres:

1. `source .claude/scripts/paths.sh` — qué instancias existen de verdad.
2. `docs/state.yaml` — fase, historias y tareas por estado.
3. `git status` y `git log --oneline -10`.
4. Últimos archivos en `docs/audits/` y su veredicto.
5. Tareas `bloqueada` y el motivo escrito en cada una.

Reporta en este orden y con esta forma:

- **Fase actual** y qué falta para cerrarla.
- **Instancias** detectadas y si coinciden con las declaradas en `state.yaml`.
- **En curso**: tarea, instancia, agente, desde cuándo.
- **Bloqueado**: qué y por qué (esto va primero si hay algo).
- **Siguiente acción recomendada**, con el comando concreto.
- **Deuda anotada**, si la hay.

Si `docs/state.yaml` no existe, dilo claramente y propón `/iniciar-proyecto`. Si `paths.sh`
devuelve `sin-inicializar` pero hay carpetas de código, avisa: **los gates se están omitiendo y
todo parece verde sin haber comprobado nada**.

Si el estado en disco contradice lo que se dijo en el chat, **gana el disco** y señala la
discrepancia.
