---
description: Escribe y ejecuta los tests Playwright de una historia
argument-hint: "[STORY-003 | vacío = suite completa]"
---

Invoca a `qa-engineer` sobre: $ARGUMENTS

1. Lee la historia y convierte **cada criterio de aceptación en un test**, con el ID del
   criterio en el título del test.
2. Verifica que las fixtures del backend estén cargadas.
3. `npx playwright test`. Itera hasta verde.
4. Guarda el reporte en `docs/qa/` y actualiza el campo `e2e:` de la historia.

Selectores por rol o `data-testid`, nunca por clase Tailwind. Cero `waitForTimeout`.
Si un test falla, diagnostica dónde está el fallo real —frontend, backend o test— y **nunca
relajes una aserción para que pase**.
