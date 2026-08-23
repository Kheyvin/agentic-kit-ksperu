---
name: user-stories
description: Escribir y mantener historias de usuario en YAML con criterios de aceptación en Gherkin. Úsalo al capturar requisitos, traducir una idea del cliente a alcance verificable, o registrar qué historias ya están implementadas.
---

# Historias de usuario en YAML

Las historias viven en `docs/stories/STORY-XXX.yaml`. YAML y no prose porque el estado se
consulta con `grep` y se procesa sin ambigüedad.

## Formato

```yaml
id: STORY-003
titulo: Listar productos con búsqueda y paginación
actor: usuario autenticado
quiero: ver el catálogo filtrable por nombre y estado
para: encontrar un producto sin recorrer todas las páginas
prioridad: alta            # alta | media | baja
estado: hecha              # borrador | acordada | en_curso | hecha | descartada
valor: "Reduce el tiempo de búsqueda; es la pantalla más usada del sistema."

criterios:
  - id: AC-1
    dado: que existen 143 productos y estoy autenticado
    cuando: abro /productos
    entonces: veo 20 filas, el total 143 y controles de paginación
  - id: AC-2
    dado: que escribo "silla" en el buscador
    cuando: pasan 300 ms sin teclear
    entonces: la URL incluye ?name=silla y la tabla muestra solo coincidencias
  - id: AC-3
    dado: que un filtro no arroja resultados
    cuando: se renderiza la tabla
    entonces: veo el vacío "sin resultados para el filtro", distinto del vacío "sin datos"

fuera_de_alcance:
  - exportación a CSV
  - edición en línea

reglas_de_negocio:
  - Solo ROLE_ADMIN ve productos archivados.

contrato_afectado:
  - "GET /api/products (SearchFilter name partial, status exact; OrderFilter name, createdAt)"

tareas: [TASK-012, TASK-014, TASK-015]
mockup: docs/mockups/products-list.html
e2e: tests/e2e/products-list.spec.js
```

## Reglas

- **Criterios observables desde fuera.** "El código usa un composable" no es un criterio;
  "la URL refleja el filtro al recargar" sí lo es.
- **Cada criterio debe poder convertirse en un test Playwright.** Si no se puede, está mal
  redactado o pertenece a la auditoría, no a la historia.
- **Estados vacíos, error y carga son criterios, no detalles.** El estándar frontend exige
  los cuatro estados: escribe al menos uno como criterio explícito.
- `fuera_de_alcance` es obligatorio: es lo que evita que la historia crezca sola.
- Una historia sin `mockup` no puede tener tareas de frontend.
- Cuando una historia pasa a `hecha`, se anotan las tareas y el spec E2E que la prueban.
  Esa trazabilidad —historia → tarea → test— es todo el registro que necesitas.
