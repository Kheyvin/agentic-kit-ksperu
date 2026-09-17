# Instrucciones del proyecto

Este proyecto usa el **Agentic Kit**. Tú (la sesión principal) orquestas; los subagentes
`backend-dev`, `frontend-dev`, `reviewer` y `qa` ejecutan. Comandos: `/iniciar` · `/planificar`
· `/tarea` · `/revisar` · `/pruebas` · `/estado`.

## Reglas

1. **Todo cambio de código pasa por una tarea** `docs/tasks/TASK-XXX.md` y la ejecuta un
   subagente con `/tarea`. No escribas código de las instancias tú mismo. Para un arreglo
   pequeño, crea la tarea con `.claude/templates/TASK.md` (objetivo + criterios, diez líneas) y
   despáchala; no hace falta `/planificar`.
2. **El estado es el frontmatter de las tareas.** `bash .claude/scripts/estado.sh` lo lee y
   `estado.sh --marcar <id> <estado>` lo cambia. No lo lleves en la conversación.
3. **Una tarea no se cierra sin gate en verde, y lo corres tú** después del subagente:
   `bash .claude/scripts/gate-backend.sh <instancia>` o `gate-frontend.sh <instancia>`. Un solo
   reintento; después, `bloqueada` y consulta al usuario. Nunca arregles el gate tú.
4. **Lee poco.** Para orquestar te basta la tarea y la salida de los scripts. No leas el código
   de las instancias ni las skills de estándares: eso lo hacen los subagentes en su contexto.
5. **Contrato API por backend** en `docs/contracts/<instancia>.md`. Quien añade o cambia un
   endpoint lo actualiza en la misma tarea.
6. **Español** en documentación, tareas y comentarios; código y nombres en inglés.
7. **Solo desarrollo**: sin CI, Docker, despliegue, releases ni CHANGELOG. Commit solo cuando el
   usuario lo pida.

## Stack fijado

SQLite en desarrollo (otro motor solo si el usuario lo pide) · login por `username` · sin
refresh token (`401` → limpiar sesión → `/login?redirect=`) · Mailer, Messenger y Mercure solo
si el usuario los pide · sin librería de animación salvo petición (GSAP → skill `gsap-vue`) ·
migraciones solo con `make:migration` (el hook bloquea escribirlas a mano).

## Instancias

N backends y N frontends; `paths.sh` los detecta (carpeta con `composer.json` + `src/` es
backend; `package.json` con `vue` es frontend). Una sola de cada capa: `backend/` y
`frontend/`. Varias: todas con prefijo (`ventas_backend`, `admin_frontend`). Cada tarea declara
una `instancia:`.

## Documentos

`docs/BRIEF.md` (qué se construye y decisiones) · `docs/contracts/<inst>.md` ·
`docs/tasks/TASK-XXX.md` (spec, criterios, estado y bitácora) · `docs/mockups/` (opcional).
Nada más.

## Al arrancar

El hook de sesión ya te da layout, instancias y resumen de tareas. No leas nada más hasta que
el usuario pida algo.
