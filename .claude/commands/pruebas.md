---
description: Verifica una historia en el navegador y escribe sus tests Playwright
argument-hint: "[STORY-003 | vacío = suite completa]"
---

Invoca a `qa-engineer` sobre: $ARGUMENTS

**Primero verifica en vivo, después codifica.** Escribir el spec a ciegas produce tests que
fallan por el selector y no por el bug.

1. Lee la historia y convierte **cada criterio de aceptación** en algo verificable.
2. Verifica las fixtures del backend cargadas (`admin` / `pass_1234`, campo `username`).
3. Pasada en vivo con el MCP del navegador, por cada criterio:
   - `browser_navigate` a la ruta.
   - `browser_console_messages` — **lo primero siempre**. Un error de consola invalida la
     pantalla aunque se vea bien: para y repórtalo.
   - `browser_evaluate` con la aserción concreta (contar filas, leer el error del campo,
     comprobar `location.search`). Datos, no impresiones.
   - `browser_resize` a 375×667 para lo que dependa del layout.
   - `browser_take_screenshot` de los estados que el usuario debe aprobar.
4. Codifica lo verificado: un `test()` por criterio, con el ID del criterio en el título.
5. `npx playwright test`. Itera hasta verde.
6. Guarda el reporte y las capturas en `docs/qa/` y actualiza el campo `e2e:` de la historia.

Selectores por rol o `data-testid`, nunca por clase Tailwind. Cero `waitForTimeout`.
No hay refresh token en este kit: no escribas tests de refresh ni de rotación.

Si un test falla, diagnostica en este orden —consola del navegador, `curl` al endpoint, y solo
entonces el propio test— y **nunca relajes una aserción para que pase**.
