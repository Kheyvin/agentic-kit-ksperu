---
description: Convierte el brief en historias de usuario y tareas autocontenidas
argument-hint: "[historia o funcionalidad a planificar; vacío = todo el brief]"
---

Invoca a `product-owner` y luego a `orchestrator`.

Alcance: $ARGUMENTS

1. `product-owner` escribe las historias en `docs/stories/STORY-XXX.yaml` con criterios Gherkin,
   `fuera_de_alcance` y los casos borde que el usuario no mencionó.
2. Muestra las historias al usuario y **pide que ordene la prioridad** antes de continuar.
3. `orchestrator` descompone cada historia priorizada en tareas `docs/tasks/TASK-XXX.md`
   usando `.claude/templates/TASK.md`, con el fragmento del contrato copiado dentro.
4. Verifica el test de autocontención de la skill `task-spec` en cada tarea antes de guardarla.
5. Escribe `docs/state.yaml` con el índice completo.
6. Muestra el plan como tabla: tarea, agente, dependencias, qué se puede paralelizar.

No empieces a ejecutar tareas en este comando.
