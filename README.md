# Agentic Kit — Symfony 8 headless + Vue 3/Vite

Carpeta `.claude/` portable: se copia dentro de cualquier proyecto y activa un equipo de
agentes con roles, skills y gates de calidad. Pensada para **un solo desarrollador** que
necesita los controles que normalmente aporta un equipo.

Todo lo que hace el kit es **entorno de desarrollo**: no hay CI, ni Docker, ni despliegue, ni
releases. De subir el proyecto se encarga el usuario.

## Instalar

```bash
git clone https://github.com/<tu-usuario>/agentic-kit.git /tmp/agentic-kit
cp -r /tmp/agentic-kit/.claude ./
cp /tmp/agentic-kit/CLAUDE.md ./
chmod +x .claude/scripts/*.sh
```

Requisitos: PHP 8.4+, Composer, Symfony CLI, Node 20+. Los hooks parsean su entrada con PHP,
así que **no hace falta `jq`** — cosa que en Git Bash de Windows no viene instalado.

## Flujo

```
/iniciar-proyecto  → pregunta la forma del proyecto, crea Symfony 8.1 y/o Vite+Vue y docs/
/descubrimiento    → el Arquitecto TE ENTREVISTA sin límite de preguntas y cierra el alcance
/planificar        → historias YAML + tareas .md autocontenidas
/maqueta           → boceto HTML con los 5 estados, antes de tocar Vue
/tarea TASK-XXX    → el Orquestador despacha al especialista y audita al volver
/auditar           → auditoría del código generado
/pruebas           → verificación en vivo con el navegador + specs Playwright
/estado            → dónde está todo, leído de docs/ y no de la memoria
```

## Los dos principios

**Cero dependencia de memoria.** Todo estado vive en `docs/`, versionado. Cada
`docs/tasks/TASK-XXX.md` es autocontenido —incluye el fragmento del contrato API copiado
dentro— así que cualquier agente lo ejecuta en frío. Borrar el historial del chat no pierde nada.

**Cero dependencia del harness.** Los agentes y skills son Markdown plano. Cambiar de
herramienta no cuesta nada porque nada vive dentro de la herramienta.

## Instancias: se detectan, no se asumen

El kit soporta **N backends y N frontends**. `paths.sh` los descubre leyendo el disco: carpeta
de primer nivel con `composer.json` + `src/` → backend; con `package.json` que dependa de `vue`
→ frontend.

| Forma | Estructura |
|---|---|
| Headless (por defecto) | `backend/` + `frontend/` |
| Solo backend / solo frontend | una capa |
| Plano | Symfony y Vite en la raíz |
| Multi-instancia | `ventas_backend/`, `admin_backend/`, `cliente_frontend/`, `admin_frontend/` |

Con varias instancias **todas llevan prefijo**, para que nadie tenga que recordar cuál era "el
backend". Cada tarea declara sobre cuál trabaja, y los gates la aceptan como argumento:

```bash
bash .claude/scripts/gate-backend.sh ventas_backend
```

Si una capa no está en el repositorio, su gate se omite en vez de fallar. Para estructuras
inusuales, fija las instancias a mano en `.claude/project.json`.

## Decisiones del stack

- **SQLite** en desarrollo. Otro motor exige cambiar `.env` y avisar.
- **Login por `username`**, no `email`.
- **Sin refresh token**: el access dura una hora, y al caducar se vuelve al login.
- Mailer, Messenger y Mercure **se preguntan**, no se instalan por defecto.
- **Sin librería de animación** por defecto. Si se pide GSAP, la skill `gsap-vue` (adaptada de
  las oficiales de GreenSock) fija el patrón: composable con carga perezosa, `gsap.context`
  con scope y `revert()` al desmontar, y `prefers-reduced-motion` respetado.

## Los gates

| Gate | Comprueba | Cuándo |
|---|---|---|
| `gate-contract.sh` | Cada contrato de `docs/contracts/` sigue igual, o cambió sin ADR ni tareas hermanas | Por tarea |
| `gate-backend.sh` | Lint PHP, mapeo Doctrine, contenedor, YAML, migraciones, secretos, DQL fuera de repos | Por tarea |
| `gate-frontend.sh` | axios en componentes, console.log, colores hardcodeados, rutas no lazy, sintaxis JS, gsap fuera de composables, markers de ScrollTrigger | Por tarea |
| `deep-check.sh` | Build de producción y auditoría de dependencias (`composer audit`, `npm audit`) | A demanda |

Los tres primeros son **rápidos a propósito**: un gate que tarda medio minuto se acaba saltando
el día que vas con prisa. Lo lento vive en `deep-check.sh` y se corre al cerrar una historia o
tras tocar dependencias.

## Los hooks

| Hook | Qué hace |
|---|---|
| `PreToolUse(Bash\|Write\|Edit)` | `guard.sh` — bloquea comandos destructivos, y crear entidades o migraciones a mano |
| `PostToolUse(Write\|Edit)` | `format.sh` — php-cs-fixer / prettier, y rechaza PHP con sintaxis inválida |
| `SessionStart` | `session-context.sh` — inyecta instancias, rama y estado real |

`bash .claude/scripts/test-guard.sh` verifica que el guard bloquea lo que debe y deja pasar lo
que debe. Córrelo si tocas `guard.sh`.

## Contenido

| Carpeta | Qué hay |
|---|---|
| `.claude/agents/` | 15 subagentes con contexto aislado y herramientas acotadas |
| `.claude/skills/` | 17 skills: estándares, protocolos y checklists |
| `.claude/commands/` | 8 comandos que arrancan cada fase |
| `.claude/templates/` | Tarea, historia, estado, ADR, auditoría, contrato |
| `.claude/scripts/` | Detección de instancias, gates ejecutables y hooks |

Las skills dicen *cómo* hacer bien las cosas; los hooks y los gates garantizan que se hagan.
Solo con skills, el día que vas con prisa el agente se las salta.
