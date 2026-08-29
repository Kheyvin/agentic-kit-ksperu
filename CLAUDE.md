# Instrucciones del proyecto

Este proyecto usa el **Agentic Kit**: un equipo de subagentes con roles definidos.
No improvises el proceso — sigue el protocolo.

## Reglas duras

1. **Nunca escribas código sin una tarea.** Si no existe `docs/tasks/TASK-XXX.md` para lo que
   se pide, invoca al `orchestrator` para que la cree primero.
2. **El estado vive en disco, no en el chat.** Antes de responder cualquier "¿cómo vamos?",
   lee `docs/state.yaml`. Después de cualquier cambio de estado, escríbelo ahí.
3. **El contrato API manda, y hay uno por backend.** `docs/contracts/<instancia>.md` es la
   fuente de verdad entre ese backend y el frontend que lo consume. Cambiarlo requiere ADR y
   actualizar ambos lados en la misma tarea.
4. **Delegación obligatoria.** Backend → `backend-developer`. Frontend → `frontend-developer`.
   Esquema → `db-architect`. Revisión → `code-auditor`. No hagas tú el trabajo de un especialista.
5. **Ningún trabajo se cierra sin gate en verde.** Ver `.claude/skills/task-spec/SKILL.md`.
6. **Español** en documentación, historias, ADRs y comentarios. Código y nombres en inglés.
7. **No asumas la estructura del proyecto.** Puede haber varios backends y varios frontends:
   ejecuta `source .claude/scripts/paths.sh` y usa `$BACKENDS` y `$FRONTENDS`. Nunca escribas
   `cd backend/` a ciegas. Si el layout sale `sin-inicializar`, **los gates se omiten y todo
   parece verde sin haber comprobado nada**: arréglalo antes de seguir.
8. **Esto es desarrollo y nada más.** No hay CI, ni Docker, ni despliegue, ni releases: no
   generes CHANGELOG, versiones semánticas ni tags, y no propongas infraestructura. De subir el
   proyecto se encarga el usuario. Los gates corren por hook en local y eso es todo lo que hay.
9. **Entidades y migraciones se generan con comandos.** `make:entity` es interactivo: se le
   pasan las respuestas por stdin. El hook bloquea crear entidades a mano y escribir en
   `migrations/`.

## Decisiones del stack que no se renegocian

- **Base de datos: SQLite** en desarrollo (`DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"`).
  Si el usuario pide otro motor, avísale de que debe cambiar `.env`.
- **Login por `username`**, no por `email`. Es lo que genera `make:user`.
- **No hay refresh token.** El access dura una hora; al caducar, `401` → el frontend limpia la
  sesión y va a `/login?redirect=<ruta>`. Nada de colas de reintento ni rotación.
- `symfony/mailer`, `symfony/messenger` y `mercure` **se preguntan**, no se instalan por defecto.
- **Sin librería de animación** por defecto: Tailwind y `<Transition>` de Vue. Si el usuario
  pide GSAP, entra con ADR y manda la skill `gsap-vue`.

## Árbol de documentación (lo crea `/iniciar-proyecto`)

```
docs/
├── state.yaml              # índice único de historias y tareas — la "memoria"
├── BRIEF.md                # qué se está construyendo y para quién
├── contracts/<inst>.md     # contrato API por backend (fuente de verdad) + su .lock
├── adr/ADR-XXX-*.md        # decisiones de arquitectura
├── stories/STORY-XXX.yaml  # historias de usuario + criterios Gherkin
├── tasks/TASK-XXX.md       # unidades de trabajo autocontenidas
├── mockups/*.html          # bocetos HTML estáticos, previos al código Vue
├── audits/AUDIT-XXX.md     # hallazgos de auditoría
└── qa/                     # specs Playwright, capturas y reportes
```

## Instancias

El kit soporta **N backends y N frontends** con nombres arbitrarios. `paths.sh` los detecta
solo: cualquier carpeta de primer nivel con `composer.json` + `src/` es un backend, y con
`package.json` que dependa de `vue` es un frontend.

Convención de nombres: con una sola instancia de cada capa, `backend/` y `frontend/`. Con
varias, **todas** llevan prefijo: `ventas_backend`, `admin_backend`, `cliente_frontend`,
`admin_frontend`.

Cada tarea declara `instancia:`. Una tarea que no dice sobre qué backend trabaja no es
autocontenida y no se despacha. Los gates aceptan la instancia como argumento:
`bash .claude/scripts/gate-backend.sh ventas_backend`.

Si una capa no está en el repositorio, su gate se omite en vez de fallar.

## Comandos

`/iniciar-proyecto` · `/descubrimiento` · `/planificar` · `/maqueta` · `/tarea` · `/auditar` ·
`/pruebas` · `/estado`

## Arranque de sesión

Al iniciar, lee `docs/state.yaml` y resume en 3 líneas: fase actual, tareas en curso,
bloqueos. Si el archivo no existe, propón `/iniciar-proyecto`.
