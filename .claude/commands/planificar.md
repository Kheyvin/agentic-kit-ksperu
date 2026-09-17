---
description: Entrevista corta, brief, contrato API y tareas del tamaño correcto
argument-hint: "[funcionalidad, bug o alcance; vacío = todo el proyecto]"
---

Carga la skill `planificacion` y aplícala a: $ARGUMENTS

Antes de preguntar nada, lee `docs/BRIEF.md` y `docs/contracts/*.md` si existen, y corre
`bash .claude/scripts/estado.sh`: no preguntes lo que ya está decidido ni repitas tareas que ya
existen. No leas el código de las instancias; si necesitas saber qué existe, `grep` una ruta o
un nombre concreto.

Resultado: `docs/BRIEF.md` al día, contratos con los endpoints nuevos, tareas en `docs/tasks/`
y la tabla final. No ejecutes ninguna tarea aquí; termina indicando la primera con
`bash .claude/scripts/estado.sh --siguiente`.
