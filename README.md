# Agentic Kit KSPerú — Symfony 8 headless + Vue 3/Vite

Una carpeta `.claude/` que se copia dentro de un proyecto y convierte a Claude Code en un
equipo pequeño: tú planificas con la sesión principal, dos desarrolladores (backend y frontend)
ejecutan cada tarea en su propio contexto, un revisor entra solo cuando hace falta y un QA
prueba en un navegador real.

Está diseñado para gastar pocos tokens y no dar vueltas: cuatro agentes, seis comandos, una
tarea por funcionalidad, tres documentos, y gates que enseñan lo que falla.

Todo ocurre en **tu entorno de desarrollo**. El kit no despliega, no monta CI, no genera
versiones. Subir el proyecto lo haces tú.

---

## Instalación

| Necesitas | Para qué |
|---|---|
| PHP 8.4+ y Composer | El backend Symfony. Con XAMPP, `php` tiene que estar en el PATH |
| Symfony CLI | Crear el proyecto y levantar el servidor |
| Node 20+ | El frontend Vite |
| **Git Bash** (solo Windows) | Los hooks y los gates son scripts `.sh` |

```bash
git clone https://github.com/Kheyvin/agentic-kit-ksperu.git /tmp/agentic-kit-ksperu
cp -r /tmp/agentic-kit-ksperu/.claude ./
cp    /tmp/agentic-kit-ksperu/CLAUDE.md ./
```

Comprueba que quedó bien:

```bash
bash .claude/scripts/test-guard.sh     # debe terminar en "18 ok, 0 fallos"
```

Si ves `$'\r': command not found`, los scripts llegaron con finales de línea de Windows:
`git config core.autocrlf false`, borra la copia y vuelve a clonar.

---

## Los seis comandos

| Comando | Qué hace | Cuándo |
|---|---|---|
| `/iniciar` | Pregunta qué construyes (capas, nombres, motor de BD, plantilla `vue`/`vue-ts`), crea las instancias y `docs/` | Una vez |
| `/planificar <idea>` | Entrevista corta (una ronda), escribe el brief, el contrato API y las tareas | Por funcionalidad |
| `/tarea TASK-XXX` | La ejecuta un subagente; la sesión principal corre el gate y la cierra | Muchas veces |
| `/revisar [TASK-XXX]` | Revisión de código, seguridad, contrato y accesibilidad en una pasada | Cuando quieras |
| `/pruebas TASK-XXX` | Verifica en el navegador y deja los tests Playwright | Al terminar una funcionalidad |
| `/estado` | Lee el disco y dice por dónde vas | Cuando vuelvas |

`/tarea siguiente` coge la primera tarea pendiente con las dependencias hechas.

---

## Un día normal

```text
Primera vez
  /iniciar                       → 4 preguntas, se crea todo, login verificado con curl
  /planificar gestión de pedidos → una ronda de preguntas, salen 2-4 tareas

Después, en bucle
  /tarea siguiente               → backend de pedidos (entidad + API + permisos) en una tarea
  /tarea siguiente               → frontend de pedidos (listado + formulario) en otra
  /pruebas TASK-002              → verificado en el navegador y con tests

Cuando vuelvas mañana
  /estado
```

---

## Qué pasa dentro de `/tarea`

1. La sesión principal lee **solo** la tarea, comprueba dependencias y la marca `en_curso`.
2. Invoca a `backend-dev` o `frontend-dev` con una sola línea: la ruta de la tarea. El
   subagente trabaja en su propio contexto con su skill precargada; lo que lea no ocupa el tuyo.
3. El subagente corre el gate antes de empezar (sabe qué ya estaba roto) y al terminar, con un
   máximo de tres ejecuciones. Cambia lo mínimo: no refactoriza ni "mejora" nada que la tarea
   no pida.
4. La sesión principal corre el gate por su cuenta. Verde → `hecha`. Rojo → un reintento con
   la salida del gate pegada. Sigue rojo → `bloqueada` y te lo cuenta. **No hay tercer intento.**
5. Si la tarea declara `revision: sí` (login, permisos, datos personales, dinero, borrado),
   entra el `reviewer`: bloqueantes → una pasada de corrección; notas → se anotan y ya.
6. Te propone el commit; se hace solo si tú lo confirmas.

---

## Qué hace el arnés por su cuenta

- **Al abrir la sesión** inyecta layout, instancias, rama y el resumen de tareas.
- **Antes de cada comando o escritura**, un guardia bloquea: borrar la base de datos,
  `schema:update`, force push, tocar `.env.local` o las claves JWT, y **escribir migraciones a
  mano** (se generan con `make:migration`). Las entidades sí se pueden escribir a mano.
- **Después de escribir un `.php`**, comprueba la sintaxis. No formatea nada: un formateador que
  reescribe el archivo rompe el siguiente `Edit` del agente.
- **Gates** (rápidos, y enseñan la salida del paso que falla):

| Gate | Bloquea | Avisa |
|---|---|---|
| Backend | sintaxis PHP de lo tocado, mapeo Doctrine y esquema en sync, contenedor, migraciones aplicadas, secretos en `src/` | consultas fuera de `src/Repository/` |
| Frontend | compila con Vite, ningún componente importa `axios` | rutas no lazy, `console.log`, GSAP fuera de `composables/` |

Si una capa no existe en el repositorio, su gate se omite.

---

## El estado vive en las tareas

```text
docs/
├── BRIEF.md            ← qué se construye, modelo de datos, decisiones (lista que se anexa)
├── contracts/<inst>.md ← un contrato de API por backend
├── tasks/TASK-XXX.md   ← objetivo, contrato, criterios, estado y bitácora del agente
└── mockups/            ← opcional
```

No hay `state.yaml`, historias, ADRs ni informes de auditoría: el frontmatter de cada tarea es
el estado (`bash .claude/scripts/estado.sh`), las decisiones son una lista en el brief y la
revisión se anexa a la tarea. Menos archivos que leer en cada paso.

**Una tarea es una funcionalidad completa en una instancia**: "Productos: entidad, migración,
CRUD con filtros y permisos" es una tarea de backend; "Productos: listado y formulario" es una
de frontend. Nunca se parte por capa técnica.

---

## Quién trabaja

| Agente | Hace | Skill precargada |
|---|---|---|
| `backend-dev` | Ejecuta tareas de backend y el bootstrap de Symfony | `backend` |
| `frontend-dev` | Ejecuta tareas de frontend y el bootstrap de Vite | `frontend` |
| `reviewer` | Revisa el diff; solo lee | `revision` |
| `qa` | Verifica en el navegador y escribe specs | `qa` |

Todos usan `model: inherit`: el modelo que elijas con `/model` en la sesión principal es el que
usan los subagentes. Cámbialo en el frontmatter de `.claude/agents/*.md` si quieres fijar uno.

Las skills `backend` y `frontend` tienen una carpeta `reference/` con los patrones de código
completos y la receta de bootstrap; los agentes las consultan por sección, no enteras. La
skill `gsap-vue` solo se carga si pides animación con GSAP; `planificacion` la usa la sesión
principal en `/planificar`.

---

## Decisiones ya tomadas

- **SQLite** en desarrollo; `/iniciar` pregunta si quieres otro motor.
- **Login por `username`**, no por email.
- **Sin refresh token.** El token dura una hora; al caducar vuelves al login conservando a
  dónde ibas.
- **Mailer, Messenger y Mercure se preguntan**, no se instalan por si acaso.
- **Sin librería de animación** por defecto.
- Documentación en **español**; código y nombres en inglés.

---

## Si algo va mal

**`/estado` dice `sin-inicializar` pero tengo carpetas de código.** Los gates se están saltando.
Las carpetas necesitan `composer.json` + `src/` (backend) o `package.json` con `vue`
(frontend); si tu estructura es rara, fija las rutas en `.claude/project.json`.

**Una tarea quedó bloqueada.** `bash .claude/scripts/estado.sh` muestra el motivo. Casi siempre
es una pregunta que te toca responder; contéstala en la tarea o en el contrato y relanza
`/tarea TASK-XXX`.

**El guardia me bloquea algo que quiero hacer.** Es para el agente, no para ti: hazlo en tu
terminal.

**Los hooks fallan en Windows.** `where bash` debe devolver primero el de Git
(`C:\Program Files\Git\usr\bin\bash.exe`), no el de WSL en `System32`.

---

## Estructura del kit

| Carpeta | Qué hay |
|---|---|
| `.claude/agents/` | 4 agentes |
| `.claude/commands/` | 6 comandos |
| `.claude/skills/` | `backend`, `frontend`, `revision`, `qa`, `planificacion`, `gsap-vue` |
| `.claude/templates/` | `TASK.md`, `CONTRACT.md`, `BRIEF.md` |
| `.claude/scripts/` | detección de instancias, guard, gates, estado, contexto de sesión |
