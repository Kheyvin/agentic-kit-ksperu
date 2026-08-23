---
name: docs-adr
description: Mantener documentación sincronizada con el código y registrar decisiones de arquitectura como ADR. Úsalo cuando cambie una API pública, se tome una decisión estructural, o haya que actualizar README, CHANGELOG o el contrato.
---

# Documentación y ADRs

## Regla de sincronización

Si una tarea cambió una **superficie pública** —endpoint, forma de respuesta, variable de
entorno, comando, contrato de composable o props de un organism— la documentación se actualiza
**en la misma tarea**. Documentar después no ocurre nunca.

Qué se actualiza según el cambio:

| Cambio | Documento |
|---|---|
| Endpoint nuevo o modificado | `docs/CONTRACT.md` |
| Variable de entorno | `README.md` + `.env.example` |
| Decisión estructural | `docs/adr/ADR-XXX-*.md` |
| Cambio visible para el usuario | `CHANGELOG.md` |
| Contrato de composable/service | JSDoc en el propio archivo |

## ADR — cuándo escribir uno

Escribe ADR cuando la decisión sea **cara de revertir**: elección de librería, estrategia de
autenticación, forma de paginación, estructura de carpetas, política de caché, modelo de
permisos. No escribas ADR para nombrar una variable.

Un ADR es corto —una página— y su valor está en **las alternativas descartadas**: dentro de seis
meses, cuando alguien proponga la opción B, el ADR explica por qué ya se dijo que no.

Plantilla en `.claude/templates/ADR.md`. Estados: `propuesto` → `aceptado` → `reemplazado por
ADR-YYY`. Un ADR nunca se borra ni se edita en su decisión: se reemplaza.

## Estilo

- Español, frases cortas, sin relleno.
- El README responde en este orden: qué es, cómo levantarlo, cómo correr los tests, dónde está
  el resto de la documentación. Nada más en la portada.
- JSDoc obligatorio en services (params y retorno), composables (contrato completo), utils y
  props no triviales. Prohibido el comentario que repite el nombre del método.
- CHANGELOG en formato Keep a Changelog, escrito **para el usuario**: "El listado de productos
  ahora recuerda los filtros al recargar", no "refactor de useCollection".
