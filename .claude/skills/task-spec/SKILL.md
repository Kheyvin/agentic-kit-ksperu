---
name: task-spec
description: Formato obligatorio de una tarea autocontenida y su definición de terminado. Úsalo al crear, leer, ejecutar o cerrar cualquier archivo docs/tasks/TASK-XXX.md, y cuando haya que decidir si un trabajo puede darse por hecho.
---

# Tarea autocontenida

Una tarea es un contrato de trabajo que **cualquier agente puede ejecutar en frío**, sin
historial de chat, sin conocer el proyecto y sin acceso al CLI que la creó. Si un agente
necesita preguntar algo para empezar, la tarea está mal escrita.

## Test de autocontención

Antes de guardar una tarea, verifica que responde por sí sola:

- [ ] ¿Qué se construye y por qué (historia de origen)?
- [ ] ¿Qué archivos exactos se pueden tocar, y cuáles están prohibidos?
- [ ] ¿Cuál es el fragmento de contrato API relevante, **copiado dentro de la tarea**?
- [ ] ¿Cuáles son los criterios de aceptación verificables?
- [ ] ¿Qué comando prueba que funciona?
- [ ] ¿Qué gate debe quedar en verde?
- [ ] ¿De qué otras tareas depende?

Copiar el fragmento del contrato dentro de la tarea es redundancia **deliberada**: elimina la
dependencia de que el agente encuentre y lea el archivo correcto.

## Plantilla

Usa `.claude/templates/TASK.md` sin modificar la estructura. Campos del frontmatter:

```yaml
id: TASK-014
titulo: Endpoint GET /api/products con filtros
historia: STORY-003
capa: backend            # backend | frontend | fullstack | infra | docs
agente: backend-developer
skills: [backend-symfony, api-contract, db-migrations]
estado: pendiente        # pendiente | en_curso | en_auditoria | bloqueada | hecha
depende_de: [TASK-012]
archivos_permitidos:
  - src/Entity/Product.php
  - src/Repository/ProductRepository.php
gates: [gate-backend]
```

## Definición de terminado (DoD)

Una tarea pasa a `hecha` **solo si todo esto es cierto**:

1. Todos los criterios de aceptación marcados `[x]` con evidencia (comando + salida).
2. El gate declarado corrió y salió en verde.
3. No se tocó ningún archivo fuera de `archivos_permitidos`.
4. La sección `## Bitácora` está escrita.
5. `docs/state.yaml` refleja el nuevo estado.
6. Si la tarea cambió una API pública, la documentación se actualizó en la misma tarea.

Cerrar una tarea sin gate en verde es la única falta que invalida el proceso completo.
Ante la duda, la tarea queda en `bloqueada` con el motivo escrito, nunca en `hecha`.

## Granularidad

Una tarea = un agente + una capa + un gate. Si necesita dos agentes, son dos tareas.
Si supera ~8 archivos o mezcla capas, divídela. Si es menor que un commit, fusiónala.
