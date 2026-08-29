# Agentic Kit KSPerú — Symfony 8 headless + Vue 3/Vite

Una carpeta `.claude/` que se copia dentro de un proyecto y convierte a Claude Code en un equipo:
un arquitecto que te entrevista, un analista que escribe las historias, especialistas que
programan cada capa, un auditor que revisa lo que escribieron y un QA que lo prueba en un
navegador de verdad.

Está pensado para **trabajar solo** y aun así tener los controles que normalmente te da un
equipo: alguien que pregunta antes de empezar, alguien que revisa antes de cerrar, y un sitio
donde consultar en qué punto estás.

Todo ocurre en **tu entorno de desarrollo**. El kit no despliega, no monta CI, no genera
versiones ni toca producción. Subir el proyecto lo haces tú, cuando quieras y como quieras.

---

## Instalación

El kit no es tu proyecto: es una carpeta que se copia **dentro** del proyecto en el que vas
a trabajar.

### Antes de empezar

| Necesitas | Para qué |
|---|---|
| PHP 8.4+ y Composer | El backend Symfony. Si usas XAMPP, asegúrate de que `php` esté en el PATH |
| Symfony CLI | Crear el proyecto y levantar el servidor de desarrollo |
| Node 20+ | El frontend Vite |
| **Git Bash** (solo Windows) | Los hooks y los gates son scripts `.sh`. Viene con Git for Windows |

No hace falta `jq`: los hooks leen su entrada con PHP.

En Windows, **Git Bash tiene que estar en el PATH** aunque tú trabajes en PowerShell. No lo
usas tú: lo usa Claude Code para ejecutar los guardias y los gates.

### Windows con Git Bash · Linux · macOS

```bash
git clone https://github.com/Kheyvin/agentic-kit-ksperu.git /tmp/agentic-kit-ksperu
cp -r /tmp/agentic-kit-ksperu/.claude ./
cp    /tmp/agentic-kit-ksperu/CLAUDE.md ./
```

### Comprobar que quedó bien

Abre Claude Code en la carpeta de tu proyecto y lanza:

```bash
bash .claude/scripts/test-guard.sh
```

Debe terminar en `16 ok, 0 fallos`. Si en su lugar ves errores tipo `$'\r': command not found`,
los scripts llegaron con finales de línea de Windows: ejecuta `git config core.autocrlf false`,
borra la copia y vuelve a clonar. El `.gitattributes` del kit ya lo evita, pero una copia hecha
a mano desde un ZIP puede traerlos.

Cuando esté en verde, escribe `/iniciar-proyecto`.

---

## Los comandos de un vistazo

| Comando | Cuándo lo usas | Con qué frecuencia |
|---|---|---|
| `/iniciar-proyecto` | Repositorio vacío, o falta una capa | Una vez |
| `/descubrimiento` | Antes de escribir nada, y antes de cada funcionalidad grande | Pocas veces |
| `/planificar` | Cuando el alcance ya está cerrado | Una vez por tanda de trabajo |
| `/maqueta` | Antes de programar cualquier pantalla | Una por pantalla |
| `/tarea TASK-XXX` | Para construir cada pieza | Muchas veces al día |
| `/auditar` | Cuando quieres una revisión extra | Ocasional |
| `/pruebas` | Cuando una historia está terminada | Una por historia |
| `/estado` | Al volver al proyecto, o cuando te pierdas | Cuando quieras |

El orden normal es el de la tabla. `/estado` se puede usar en cualquier momento.

---

## Cómo se usa cada comando

### `/iniciar-proyecto`

**Cuándo:** el primer día, con el repositorio vacío. También si ya tienes el backend y quieres
añadir el frontend (o al revés).

**Qué te va a preguntar:**

- ¿Qué construimos? Solo backend · solo frontend · **headless** (API + SPA) · varias instancias.
- Si hay varias, cómo se llama cada una y **qué frontend consume qué backend**.

**Qué hace después, sin que tengas que pedirlo:** crea el proyecto Symfony con API Platform, la
base de datos SQLite, el usuario con login por `username`, las claves JWT, las fixtures con un
usuario de prueba, y comprueba con un `curl` que el login devuelve un token. Luego crea el
proyecto Vite con Vue, Router, Pinia, Axios y Tailwind. Y por último el árbol `docs/`.

**Cómo sabes que ha ido bien:** el `curl` final devuelve algo con esta forma:

```json
{ "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXUyJ9..." }
```

Si no devuelve `token`, el backend no está terminado y el propio comando te lo dirá.

**Nombres de carpeta:** con una sola instancia de cada capa, `backend/` y `frontend/`. Con
varias, todas llevan prefijo: `ventas_backend/`, `admin_backend/`, `cliente_frontend/`.

---

### `/descubrimiento`

**Cuándo:** justo después de crear el proyecto, y cada vez que vayas a meter una funcionalidad
grande.

```text
/descubrimiento un sistema para gestionar los pedidos de mi tienda
```

**Qué pasa:** el arquitecto **te entrevista**. Sin límite de preguntas: irá por temas y esperará
tu respuesta antes de seguir. Si contestas algo vago, repreguntará con opciones concretas. Si
algo que dices al final contradice una decisión de antes, vuelve atrás y lo rehace.

Es la parte que más pereza da y la que más tiempo ahorra. Un proyecto que empieza a programarse
con el alcance difuso se reescribe entero.

**Qué produce:** `docs/BRIEF.md`, un contrato de API por cada backend en `docs/contracts/`, los
primeros ADR (decisiones de arquitectura) y el modelo de datos.

**Termina pidiéndote confirmación explícita.** Hasta que no confirmes, no se planifica ni se
programa nada.

**Lo que no te va a preguntar:** dónde despliegas, qué servidor usas, si quieres Docker. Nada de
eso existe aquí.

---

### `/planificar`

**Cuándo:** después de confirmar el discovery.

**Qué pasa, en dos pasos:**

1. El analista escribe las **historias de usuario** en `docs/stories/`, con criterios de
   aceptación y los casos borde que tú no mencionaste (qué se ve mientras carga, qué pasa si no
   hay datos, qué ve alguien sin permiso…).
2. Te las enseña y **te pide que las ordenes por prioridad**. Esa decisión es tuya, no suya.
3. Con el orden que le des, el orquestador parte cada historia en **tareas** en `docs/tasks/`.

**Qué es una tarea:** un archivo que cualquier agente puede ejecutar en frío, sin haber visto la
conversación. Lleva dentro copiado el trozo del contrato de API que le toca, qué archivos puede
tocar, cómo se comprueba que funciona y de qué otras tareas depende.

**No ejecuta nada.** Al terminar tienes una tabla con las tareas, quién hace cada una y cuáles
se pueden hacer a la vez.

---

### `/maqueta`

**Cuándo:** antes de escribir el primer componente Vue de una pantalla.

```text
/maqueta STORY-003 listado de productos con filtros
```

**Por qué existe:** cambiar un archivo HTML suelto cuesta segundos; cambiar componentes, stores
y rutas cuesta horas. El sitio para discutir el diseño es la maqueta, no el código.

**Qué produce:** un `.html` en `docs/mockups/` que abres con doble clic. Dentro verás **los cinco
estados apilados y rotulados**: cargando, vacío, vacío por filtro, error y con datos. Con datos
feos a propósito —nombres larguísimos, cifras de seis dígitos, veinte filas— porque los datos
bonitos esconden los fallos de maquetación.

**Qué se espera de ti:** te hará preguntas concretas, del tipo "¿las acciones van en la última
columna o en un menú por fila?". Responde esas; "no me convence" no le sirve para nada.

Itera lo que haga falta. Si dos rondas seguidas no cierran ninguna decisión, te dirá que el
problema es que la historia no está clara y la devolverá al analista.

---

### `/tarea TASK-XXX`

**Cuándo:** es el comando que más vas a usar. Una vez por cada tarea del plan.

```text
/tarea TASK-014
```

**Qué pasa por dentro:**

1. Comprueba que las tareas de las que depende ya están hechas. Si no, no arranca.
2. Si es de frontend y no hay maqueta aprobada, la pide antes.
3. Se la pasa al especialista que toca: `backend-developer`, `frontend-developer`,
   `db-architect`… Le da **solo la ruta de la tarea**, nada más. Si la tarea está bien escrita,
   le sobra; si le falta algo, la tarea estaba mal y se arregla ahí, no parcheando el chat.
4. Cuando el especialista termina, el **auditor revisa el diff** automáticamente. Si toca login,
   permisos o datos personales, revisa también el de seguridad.
5. Veredicto: aprobado → la tarea se cierra. Rechazado → vuelve al especialista con los
   hallazgos, y se reintenta una vez. Si falla otra vez, queda bloqueada y te pregunta a ti.

**Lo importante:** tú no tienes que acordarte de pedir la revisión. Va incluida.

---

### `/auditar`

**Cuándo:** casi nunca hace falta, porque `/tarea` ya audita. Úsalo si has escrito código a mano,
si quieres una segunda opinión sobre algo que ya está, o para revisar el diff actual sin más.

```text
/auditar              ← revisa lo que haya sin commitear
/auditar TASK-014     ← revisa una tarea concreta
```

**Qué produce:** un informe en `docs/audits/` con cada hallazgo localizado en archivo y línea,
el código actual, la corrección propuesta y por qué importa. Y un veredicto: aprobado, aprobado
con observaciones, o rechazado.

Según lo que toque el cambio, llama además al revisor de accesibilidad, al de rendimiento o al
de seguridad.

---

### `/pruebas`

**Cuándo:** cuando todas las tareas de una historia están hechas.

```text
/pruebas STORY-003
```

**Qué pasa, en dos pasadas:**

1. **Verificación en vivo.** Abre la pantalla en un navegador de verdad, mira **la consola**
   antes que nada (un error de JavaScript invalida la pantalla aunque se vea bien), comprueba el
   DOM, la redimensiona a móvil y saca capturas.
2. **Tests de regresión.** Convierte cada criterio de aceptación en un test de Playwright, para
   que eso mismo no se rompa dentro de tres semanas sin que nadie se entere.

**Qué produce:** los `.spec.js`, el reporte y las capturas en `docs/qa/`.

Si un test falla, diagnostica de dónde viene el fallo —del frontend, del backend o del propio
test— antes de tocar nada. **Nunca relaja una comprobación para que pase**, que es la forma más
rápida de tener una suite verde que no significa nada.

---

### `/estado`

**Cuándo:** al volver al proyecto después de unos días, cuando no recuerdes por dónde ibas, o
cuando algo no cuadre.

**Qué hace:** lee el disco, no la conversación. Te dice la fase actual, qué instancias detecta,
qué hay en curso, **qué está bloqueado y por qué** (eso va primero), cuál es la siguiente acción
recomendada con el comando exacto, y la deuda técnica anotada.

Si lo que dice el disco contradice lo que se dijo en el chat, **gana el disco** y te señala la
diferencia.

---

## Un día normal

```text
Primera vez
  /iniciar-proyecto     → responde 3-4 preguntas, se crea todo
  /descubrimiento       → te entrevista, tú contestas, confirmas al final
  /planificar           → salen las historias, tú las ordenas, salen las tareas

Después, en bucle
  /maqueta STORY-003    → apruebas el diseño
  /tarea TASK-012       → entidad y migración
  /tarea TASK-014       → endpoint
  /tarea TASK-015       → pantalla
  /pruebas STORY-003    → verificado y con tests

Cuando vuelvas mañana
  /estado               → por dónde ibas
```

---

## Qué hace el arnés por su cuenta

Esta es la parte que no tienes que pedir: pasa sola.

### Al abrir la sesión

Antes de que escribas nada, se le inyecta a Claude qué instancias hay en el repositorio, en qué
rama estás y cuántas tareas hay en curso o bloqueadas. Así no empieza a trabajar suponiendo
cosas.

### Antes de ejecutar un comando o escribir un archivo

Un guardia intercepta y **bloquea**:

- Comandos que destruyen datos: borrar la base de datos, actualizar el esquema saltándose las
  migraciones, un `push --force`.
- Tocar secretos o las claves JWT.
- **Crear una entidad a mano o escribir una migración a mano.** Eso se genera con
  `make:entity` y `make:migration`, siempre. Editar una entidad ya generada sí se permite: es
  donde se añaden los atributos de API Platform.

No es un aviso que se pueda ignorar: el comando no llega a ejecutarse.

### Después de escribir un archivo

Se formatea solo (php-cs-fixer o prettier, según el archivo). Si el PHP tiene un error de
sintaxis, se rechaza en el momento en vez de descubrirlo tres pasos después.

### Antes de cerrar cualquier tarea

Se ejecutan los **gates**. Son rápidos a propósito, porque un control que tarda medio minuto se
acaba saltando el día que vas con prisa:

| Gate | Qué comprueba |
|---|---|
| Contrato | Que el contrato de API no ha cambiado sin su ADR y sus dos tareas |
| Backend | Sintaxis PHP, mapeo de Doctrine, contenedor, migraciones aplicadas, secretos en el código, consultas fuera de los repositorios |
| Frontend | Que ningún componente llame a la red directamente, que no queden `console.log`, colores a fuego, rutas no perezosas ni restos de depuración |

Lo lento —compilar para producción y auditar dependencias— vive aparte y se lanza cuando toca:

```bash
bash .claude/scripts/deep-check.sh
```

Si una capa no existe en tu repositorio, su gate se salta en vez de fallar.

### El estado vive en `docs/`, no en el chat

```text
docs/
├── state.yaml          ← en qué punto está todo
├── BRIEF.md            ← qué se está construyendo
├── contracts/          ← un contrato de API por backend
├── adr/                ← por qué se decidió cada cosa
├── stories/            ← historias y criterios de aceptación
├── tasks/              ← las unidades de trabajo
├── mockups/            ← las maquetas HTML
├── audits/             ← los informes de revisión
└── qa/                 ← tests, capturas y reportes
```

Todo eso se versiona con tu código. Puedes borrar el historial de la conversación y no pierdes
nada: cada tarea es autosuficiente y cualquier agente la retoma en frío.

### Quién trabaja

15 agentes especializados, cada uno con su contexto aislado y sus herramientas limitadas —el
auditor, por ejemplo, no puede escribir código: solo informes—. Y 17 guías de estándares que
dicen cómo se hace bien cada cosa en este stack.

Las guías dicen *cómo*; los guardias y los gates garantizan que se cumpla. Solo con guías, el
día que vas con prisa el agente se las salta.

---

## Decisiones ya tomadas

No hace falta que las repitas en cada sesión; están en `CLAUDE.md` y todos los agentes las
conocen.

- **SQLite** en desarrollo. Si quieres otro motor, te avisará de que hay que cambiar `.env`.
- **Login por `username`**, no por email.
- **Sin refresh token.** El token dura una hora; al caducar vuelves al login conservando a dónde
  ibas.
- **Mailer, Messenger y Mercure se preguntan**, no se instalan por si acaso.
- **Sin librería de animación** por defecto: Tailwind y las transiciones de Vue. Si pides GSAP,
  entra con su ADR y su estándar propio.
- Documentación y comentarios en **español**; código y nombres en inglés.

---

## Si algo va mal

**`/estado` dice `sin-inicializar` pero tengo carpetas de código.** Es el aviso importante: los
gates se están saltando y todo parece correcto sin haber comprobado nada. Revisa que tus carpetas
tengan `composer.json` + `src/` (backend) o `package.json` con `vue` (frontend), o fija las rutas
a mano en `.claude/project.json`.

**Una tarea quedó bloqueada.** Mira `docs/state.yaml`: el motivo está escrito. Casi siempre es
una decisión que te toca tomar a ti.

**El guardia me bloquea algo que quiero hacer.** Si es borrar la base de datos o forzar el
esquema, hazlo tú en tu terminal. El bloqueo es para el agente, no para ti.

**Quiero comprobar que el guardia funciona:**

```bash
bash .claude/scripts/test-guard.sh
```

---

## Estructura del kit

| Carpeta | Qué hay |
|---|---|
| `.claude/agents/` | 15 especialistas |
| `.claude/skills/` | 17 guías de estándares |
| `.claude/commands/` | Los 8 comandos |
| `.claude/templates/` | Plantillas de tarea, historia, ADR, contrato… |
| `.claude/scripts/` | Gates, guardias y detección de instancias |
