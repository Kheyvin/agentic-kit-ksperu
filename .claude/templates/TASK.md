---
id: TASK-XXX
titulo:
historia: STORY-XXX
capa: backend            # backend | frontend | fullstack | infra | docs | qa
agente: backend-developer
skills: [backend-symfony, api-contract]
estado: pendiente        # pendiente | en_curso | en_auditoria | bloqueada | hecha
depende_de: []
archivos_permitidos:
  - src/...
gates: [gate-backend]
mockup:                  # obligatorio si capa incluye frontend
---

# TASK-XXX — <título>

## Objetivo

Una frase: qué existe al terminar esta tarea que no existía antes.

## Contexto necesario

Todo lo que el agente necesita saber. **Autocontenido**: quien ejecuta esta tarea no tiene
historial de conversación ni conoce el proyecto.

- Historia de origen y por qué importa.
- Estado actual del código relevante (qué ya existe, qué no).
- Decisiones ya tomadas que condicionan esta tarea (con el ADR si aplica).

## Fragmento del contrato API

Copia aquí, literal, la parte de `docs/CONTRACT.md` que aplica. La redundancia es deliberada:
elimina la dependencia de que el agente encuentre el archivo correcto.

```
GET /api/... 
Request:  ...
200:      { ... }
Errores:  401 · 403 · 422 con violations[]
```

## Alcance

**Incluye**
- ...

**No incluye** (esto va en otra tarea)
- ...

## Criterios de aceptación

- [ ] AC-1 — verificable, observable desde fuera
- [ ] AC-2 —
- [ ] AC-3 —

## Cómo se verifica

```bash
# comandos exactos que prueban que funciona
bash .claude/scripts/gate-backend.sh
```

## Gate

Debe salir en verde antes de cerrar. Si no lo hace, la tarea queda `bloqueada`, nunca `hecha`.

---

## Bitácora

> La escribe el agente que ejecuta. Sin esto, la tarea no se cierra.

- **Ejecutada por:** 
- **Fecha:** 
- **Archivos tocados:** 
- **Decisiones tomadas:** 
- **Gate:** verde / rojo — salida relevante
- **Pendiente o deuda generada:** 
