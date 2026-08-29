---
name: orchestration
description: Protocolo de orquestación multi-agente. Úsalo al planificar trabajo, descomponer una funcionalidad en tareas, decidir qué agente ejecuta qué, o cuando el usuario pregunta el estado del proyecto. Define el ciclo discovery → plan → mockup → build → audit → qa y el contrato entre agentes.
---

# Protocolo de orquestación

## Cadena de valor (no se salta ningún eslabón)

```
1. DISCOVERY   architect + product-owner → docs/BRIEF.md, docs/contracts/*.md, docs/adr/
2. PLAN        orchestrator             → docs/stories/*.yaml, docs/tasks/*.md, docs/state.yaml
3. MOCKUP      ux-prototyper            → docs/mockups/*.html   (solo tareas de UI)
4. BUILD       backend|frontend-dev     → código
5. AUDIT       code-auditor + security  → docs/audits/AUDIT-*.md
6. QA          qa-engineer (Playwright) → tests/e2e/*.spec.js + reporte
7. DOCS        tech-writer              → README, ADRs, contrato
```

**La cadena termina en DOCS.** No hay fase de release: no se generan CHANGELOG, versiones
semánticas ni tags, y no se despliega nada. Todo esto es entorno de desarrollo; subir el
proyecto es cosa del usuario y no se propone por iniciativa propia.

Una tarea de UI **no puede pasar a BUILD sin mockup HTML aprobado**. Una tarea de cualquier
tipo **no puede pasar a QA sin auditoría en verde**.

Con varias instancias, cada tarea declara `instancia:` en su frontmatter. Una tarea que no
dice sobre qué backend trabaja no es autocontenida y no se despacha.

## Reglas de despacho

| Si la tarea toca... | Agente |
|---|---|
| `src/Entity`, `src/Repository`, `migrations/` | `db-architect` primero, luego `backend-developer` |
| `src/Service`, `src/State`, `src/Controller`, `config/packages` | `backend-developer` |
| `src/components`, `src/views`, `src/stores`, `src/composables` | `frontend-developer` |
| Pantalla nueva sin diseño definido | `ux-prototyper` antes que `frontend-developer` |
| Cambio en `docs/contracts/<instancia>.md` | `architect` (con ADR) y luego DOS tareas: backend y frontend de esa instancia |
| Revisión de un diff | `code-auditor` |
| Login, permisos, datos personales | `security-reviewer` obligatorio además del auditor |

## Reglas de paralelismo

- **Paralelizable:** tareas con `archivos_permitidos` disjuntos y sin `depende_de` entre sí.
  Backend y frontend de la misma historia pueden ir en paralelo **solo si el contrato ya está
  cerrado**, porque el contrato es lo único que comparten.
- **Serial obligatorio:** migraciones (una a la vez, y por instancia) y cambios de contrato.
- **Entre instancias:** dos backends distintos son código disjunto y van en paralelo sin
  problema. Lo que nunca va en paralelo es la misma instancia tocada por dos tareas.
- Máximo 3 agentes en paralelo. Más allá, el coste de reconciliar diffs supera la ganancia.

## Handoff entre agentes

El único canal de comunicación entre agentes es **el sistema de archivos**. Un agente:

1. Recibe una única instrucción: *"ejecuta docs/tasks/TASK-014.md"*.
2. Lee esa tarea, que es autocontenida.
3. Escribe código y, al terminar, escribe su bitácora en la sección `## Bitácora` de la
   propia tarea (qué hizo, qué archivos tocó, qué gate corrió, qué quedó pendiente).
4. Devuelve al orquestador un resumen de ≤10 líneas.

Nunca se pasa contexto "de memoria" entre agentes. Si el agente B necesita algo que hizo A,
lo lee del archivo de tarea de A o del código.

## Actualización de estado

Después de cada transición, el orquestador reescribe `docs/state.yaml`. Ese archivo es la
única respuesta válida a "¿cómo vamos?". Nunca contestes esa pregunta de memoria.

## Cuándo parar y preguntar al humano

Detén el flujo y consulta si: hay que elegir entre dos arquitecturas con coste de reversión
alto; una historia toca dinero, datos personales o borrado irreversible; el contrato API debe
romperse; o dos tareas se contradicen. En todo lo demás, avanza.
