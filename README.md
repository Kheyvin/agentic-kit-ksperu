# Agentic Kit — Symfony 8 headless + Vue 3/Vite

Carpeta `.claude/` portable: se copia dentro de cualquier proyecto y activa un equipo de
agentes con roles, skills y gates de calidad. Pensada para **un solo desarrollador** que
necesita los controles que normalmente aporta un equipo.

## Instalar

```bash
git clone https://github.com/<tu-usuario>/agentic-kit.git /tmp/agentic-kit
cp -r /tmp/agentic-kit/.claude ./
cp /tmp/agentic-kit/CLAUDE.md ./          # Claude Code
cp /tmp/agentic-kit/AGENTS.md ./          # Codex y otros harnesses
chmod +x .claude/scripts/*.sh
```

O como submódulo, para recibir mejoras:

```bash
git submodule add https://github.com/<tu-usuario>/agentic-kit.git .agentic-kit
ln -s .agentic-kit/.claude .claude
```

## Flujo

```
/init-project      → pregunta el layout, crea Symfony 8.1 y/o Vite+Vue y el árbol docs/
/discovery         → el Arquitecto TE ENTREVISTA por bloques y cierra el alcance
/plan              → historias YAML + tareas .md autocontenidas
/mockup            → boceto HTML con los 5 estados, antes de tocar Vue
/task TASK-XXX     → el Orquestador despacha al especialista y audita al volver
/audit             → auditoría del código generado
/qa                → Playwright, un test por criterio de aceptación
/release           → gates, changelog y tag
/status            → dónde está todo, leído de docs/ y no de la memoria
```

## Los dos principios

**Cero dependencia de memoria.** Todo estado vive en `docs/`, versionado. Cada
`docs/tasks/TASK-XXX.md` es autocontenido —incluye el fragmento del contrato API copiado
dentro— así que cualquier agente lo ejecuta en frío. Borrar el historial del chat no pierde nada.

**Cero dependencia del harness.** Los agentes y skills son Markdown plano. Claude Code los
carga solo; Codex los usa vía `AGENTS.md` y `.claude/codex/sync-codex.sh`. Cambiar de
herramienta no cuesta nada porque nada vive dentro de la herramienta.

## Layout: se detecta, no se asume

`monorepo` · `plano` · `solo-backend` · `solo-frontend` · `repos-separados`.
`paths.sh` los detecta y los gates se adaptan: si una capa no está, su gate se omite en vez de
fallar. Para estructuras inusuales, fija las rutas en `.claude/project.json`.

Con repos separados, `gate-contract.sh` compara el hash de `docs/CONTRACT.md` entre ambos: es
lo único que impide que el contrato diverja en silencio.

## Contenido

| Carpeta | Qué hay |
|---|---|
| `.claude/agents/` | 17 subagentes con contexto aislado y herramientas acotadas |
| `.claude/skills/` | 17 skills: estándares, protocolos y checklists |
| `.claude/commands/` | 9 comandos que arrancan cada fase |
| `.claude/templates/` | Tarea, historia, estado, ADR, auditoría, contrato, CI opcional |
| `.claude/scripts/` | Detección de rutas y gates ejecutables |
| `.claude/codex/` | Puente para Codex u otros harnesses |

## CI e infraestructura

El kit **no instala CI ni Docker**. Mientras `infra.ci` e `infra.deploy` sigan sin decidir en
`docs/state.yaml`, el agente `devops` no propone infraestructura y los gates corren por hook en
local. Las plantillas de GitHub Actions y GitLab CI esperan en `.claude/templates/ci/`; ambas
se limitan a ejecutar los mismos `gate-*.sh` para que no existan dos definiciones de "correcto".

## Los gates

| Gate | Comprueba |
|---|---|
| `gate-contract.sh` | El contrato API no cambió sin ADR ni tareas hermanas |
| `gate-backend.sh` | Lint PHP, mapeo Doctrine, contenedor, migraciones, secretos, DQL fuera de repos, CVEs |
| `gate-frontend.sh` | Build, axios en componentes, console.log, colores hardcodeados, rutas no lazy, CVEs |

Las skills dicen *cómo* hacer bien las cosas; los hooks y los gates garantizan que se hagan.
Solo con skills, el día que vas con prisa el agente se las salta.
