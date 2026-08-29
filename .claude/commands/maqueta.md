---
description: Genera un mockup HTML estático para una pantalla antes de escribir Vue
argument-hint: "STORY-003 | descripción de la pantalla"
---

Invoca a `ux-prototyper`.

Pantalla: $ARGUMENTS

Requisitos del entregable en `docs/mockups/<slug>.html`:

- Autocontenido, Tailwind por CDN, tokens del proyecto declarados arriba (los mismos que
  `@theme` en `src/style.css`).
- Los cinco bloques rotulados y apilados: loading, empty, filtered-empty, error, success.
- Datos falsos hostiles: textos largos, cifras grandes, 20 filas, algún campo vacío.
- Móvil primero, con la variante de escritorio visible.
- Checklist de `a11y` aplicado aquí, no después.
- Bloque comentado final con el mapa Atomic Design y el endpoint del contrato que alimenta
  la pantalla, indicando **de qué instancia** viene.

Presenta el resultado y haz preguntas **decidibles** sobre el diseño (no "¿te gusta?").

Itera las rondas que hagan falta mientras cada una cierre algo. Si dos rondas seguidas terminan
sin cerrar ninguna decisión, el problema no es el diseño sino la historia: dilo y devuélvela a
`product-owner`.
