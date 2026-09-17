---
name: qa
description: Verificación end-to-end de una tarea con Playwright — primero en vivo con el navegador (consola, DOM, móvil) y después como spec de regresión por criterio de aceptación; reglas de selectores, cobertura mínima y diagnóstico de fallos. Úsalo en /pruebas o al crear o depurar un spec E2E.
---

# QA end-to-end con Playwright

Dos pasadas, en este orden. Escribir el spec a ciegas produce tests que fallan por el selector y
no por el bug; verificar en vivo sin codificar produce una app que se rompe mañana en silencio.

## Antes de empezar

Backend arrancado con fixtures (`admin`/`pass_1234`, `user`/`pass_1234`; el campo de login es
**`username`**) y frontend en `npm run dev`. Lee los criterios de aceptación de la tarea: cada
uno se convierte en una comprobación concreta. Con varios frontends, cada instancia tiene su
`baseURL` y su proyecto de Playwright.

## Pasada 1 — en vivo, con el MCP del navegador

Para cada criterio:

1. `browser_navigate` a la ruta.
2. `browser_console_messages` — **lo primero, siempre.** Un error de consola invalida la
   pantalla aunque se vea bien: se para y se reporta.
3. `browser_snapshot` para ver el árbol de accesibilidad y localizar controles por rol;
   `browser_click`, `browser_fill_form` y `browser_type` para recorrer el flujo (login incluido).
4. `browser_evaluate` con la aserción concreta: contar filas, leer el texto del error del campo,
   comprobar `location.search`. Datos, no impresiones.
5. `browser_resize` a 375×667 y repetir lo que dependa del layout (móvil primero).
6. `browser_take_screenshot` solo de lo que el usuario deba aprobar.

Una captura es evidencia para el humano; la aserción es `browser_evaluate`.

## Pasada 2 — spec de regresión

- `tests/e2e/<slug>.spec.js` en la instancia frontend; un `test()` por criterio, con su id en el
  título: `test('AC-2: la búsqueda filtra tras el debounce', ...)`.
- Selectores por rol (`getByRole`, `getByLabel`) o `data-testid`. **Nunca por clase Tailwind.**
- Cero `waitForTimeout`: `expect(...).toBeVisible()`, `waitForResponse` para el debounce.
- Tests independientes; login programático reutilizable en `tests/e2e/fixtures/auth.js`.
- `npx playwright test tests/e2e/<slug>.spec.js` hasta verde; luego la suite completa.

## Cobertura mínima que se mantiene viva

Smoke (carga sin errores de consola, login, ruta protegida redirige a `/login?redirect=`,
listado principal con filas) · auth (`401` → login, rol insuficiente → `/403`) · listados
(paginación y filtros en la URL, recargar reproduce el estado, vacío filtrado ≠ vacío sin datos)
· formularios (`422` pintado en el campo correcto, doble submit bloqueado) · errores (`500`
simulado con `page.route()` muestra reintentar) · responsive (la pantalla principal a 375 px no
desborda). No hay refresh token: no se escriben tests de refresh.

## Cuando un test falla

Diagnostica antes de tocar nada, en este orden:

1. `browser_console_messages` en esa ruta: error de JS → el fallo es del frontend y el test tiene razón.
2. `curl` al endpoint con el token de las fixtures: otra forma de respuesta → fallo del backend o del contrato.
3. Si ambas capas responden bien, el test estaba mal escrito: arréglalo y anota por qué.

**Nunca relajes una aserción para que pase.** Si el código está mal, deja el test rojo, escribe
el hallazgo en la sección `## QA` de la tarea y devuelve el control: la corrección es otra tarea.
