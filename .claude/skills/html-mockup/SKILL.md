---
name: html-mockup
description: Producir bocetos y maquetas HTML estáticas con Tailwind desde CDN antes de escribir componentes Vue. Úsalo cuando haya que diseñar una pantalla nueva, validar layout o estados de UI con el usuario, o cuando una historia no tenga mockup aprobado todavía.
---

# Mockups HTML antes de Vue

**Ningún componente Vue se escribe sin un mockup HTML aprobado.** Iterar sobre un archivo
HTML estático cuesta segundos; iterar sobre componentes, stores y rutas cuesta horas y ensucia
el repositorio. El mockup es el lugar donde se discute el diseño, no el código Vue.

## Reglas

- Un archivo por pantalla: `docs/mockups/<slug>.html`. Autocontenido, abrible con doble clic.
- Tailwind vía CDN (`<script src="https://cdn.tailwindcss.com"></script>`) **solo aquí**:
  el mockup es un artefacto de documentación, no entra al build.
- Los tokens del mockup deben ser los mismos que los de `@theme` en `src/styles/main.css`.
  Declara el bloque de tokens arriba del archivo para que el traspaso sea mecánico.
- **Datos falsos pero realistas**: nombres largos que desbordan, precios de 6 cifras, listas
  de 20 filas. Los datos bonitos ocultan los bugs de layout.
- Sin JavaScript de negocio. Como mucho, un `<script>` mínimo para alternar entre estados.

## Los cuatro estados, siempre

Cada mockup muestra las cuatro variantes en la misma página, apiladas y rotuladas:

```html
<section data-state="loading">  <!-- skeletons -->
<section data-state="empty">    <!-- "sin datos" + CTA -->
<section data-state="filtered-empty"> <!-- "sin resultados para el filtro" -->
<section data-state="error">    <!-- mensaje + botón reintentar -->
<section data-state="success">  <!-- caso normal -->
```

Y las variantes responsive: móvil primero, luego `md:`/`lg:`.

## Anotación para el traspaso

Al final de cada mockup, un bloque HTML comentado con el mapa Atomic Design:

```html
<!--
ATOMS:      BaseButton(variant=primary|danger), BaseInput, BaseBadge, BaseSpinner
MOLECULES:  FormField, SearchBar, PaginationBar
ORGANISMS:  ProductsTable (props: items, total, loading; emits: row-selected, page-change)
VIEW:       views/products/ProductListView.vue  → usa useCollection(productService.list)
CONTRATO:   GET /api/products?page&itemsPerPage&name&order[createdAt]
-->
```

Este bloque es lo que lee `frontend-developer` para implementar. Un mockup sin él está
incompleto: obliga al siguiente agente a inventar la descomposición de componentes.

## Aprobación

El mockup lo aprueba el humano. Hasta que la historia no tenga `mockup:` apuntando a un
archivo existente, sus tareas de frontend quedan en `bloqueada`.
