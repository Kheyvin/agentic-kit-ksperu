---
name: planificacion
description: Cómo convertir una petición en brief, contrato API y tareas del tamaño correcto — entrevista corta y acotada, decisiones anotadas, una tarea por funcionalidad e instancia. Úsalo en /planificar y cuando el usuario pida algo nuevo que no sea una tarea ya escrita.
---

# Planificación

Objetivo: salir con tareas que un subagente ejecute en frío, en el menor número de rondas
posible. Todo se escribe en disco; nada queda solo en la conversación.

## 1. Entrevista (una ronda; dos como máximo)

Pregunta **solo** lo que cambia el diseño y no está ya en la petición ni en `docs/BRIEF.md`:

- Quién lo usa y qué puede hacer cada rol.
- Entidades principales: campos que no pueden faltar, relaciones, qué se borra y qué se archiva.
- La pantalla que se usa a diario (marca la prioridad real).
- Qué queda fuera esta vez.
- Solo si aplica: volumen (cientos, miles o millones), integraciones o correos (Mailer,
  Messenger y Mercure se preguntan, nunca se instalan por defecto), dos personas editando lo mismo.

Agrupa todo en **un solo mensaje** (≤ 8 preguntas, cada una con opciones concretas). Una
segunda ronda solo si una respuesta abre una bifurcación real. Nunca una tercera: decide, anota
la suposición en Decisiones y sigue. No preguntes por despliegue, CI ni servidores.

Para un bug o un cambio pequeño no hay entrevista: localízalo en una línea y crea la tarea.

## 2. Escribe, en este orden

1. `docs/BRIEF.md` — créalo con `.claude/templates/BRIEF.md` o actualízalo: alcance, modelo de
   datos (una línea por entidad) y decisiones nuevas (anexadas con fecha, nunca reescritas).
2. `docs/contracts/<backend>.md` — cada endpoint nuevo: operación, seguridad, campos con grupos y
   validación, filtros. **Antes que las tareas**: el frontend se escribe contra esto.
3. `docs/tasks/TASK-XXX.md` — con `.claude/templates/TASK.md`. Numeración correlativa
   (`ls docs/tasks` para ver la última).

## 3. Tamaño de una tarea

- **Una tarea = una funcionalidad completa en una instancia.** "Productos: entidad, migración,
  CRUD con filtros y permisos" es UNA tarea de backend. "Productos: listado con filtros y
  formulario" es UNA tarea de frontend. Una funcionalidad son una o dos tareas, no cinco.
- Se divide solo si mezcla instancias o si a una persona le llevaría más de un día. Nunca por
  capa técnica (entidad, endpoint y voter por separado).
- El backend va antes que el frontend de la misma funcionalidad (`depende_de`). Dos
  funcionalidades independientes no se encadenan.
- `revision: sí` cuando toque login, permisos, datos personales, dinero o borrado. En el resto, `no`.
- Autocontenida: quien la ejecuta no ha visto esta conversación. Contexto ≤ 15 líneas, fragmento
  del contrato copiado literal, criterios observables desde fuera (petición y respuesta, o lo que
  ve el usuario), fuera de alcance explícito. En tareas de frontend con datos, los estados de
  carga, vacío y error son criterios.

## 4. Entrega

Tabla: id · título · instancia · agente · depende_de · revisión. Di cuál es la primera
(`bash .claude/scripts/estado.sh --siguiente`). No ejecutes ninguna tarea aquí.

## Cuándo parar y preguntar

Dos arquitecturas viables con coste de reversión alto; dinero, datos personales o borrado
irreversible; cambiar un endpoint que el frontend ya consume. En todo lo demás, decide y anótalo.
