---
name: qa-playwright
description: Verificar la SPA y la API con Playwright — primero en vivo con el MCP del navegador (navegar, consola, captura, evaluar, redimensionar) y después codificado como spec de regresión. Úsalo al verificar criterios de aceptación de una historia, al crear specs E2E o al diagnosticar un fallo de test.
---

# QA end-to-end con Playwright

QA tiene **dos modos y se hacen en este orden**:

1. **Verificación en vivo con el MCP del navegador.** Abres la pantalla de verdad, miras la
   consola, sacas una captura y compruebas el DOM. Sirve para saber si algo funciona *ahora*.
2. **Spec de regresión.** Lo que quedó verificado se escribe como `.spec.js` para que no se
   rompa mañana sin que nadie se entere.

Escribir el spec primero, a ciegas, produce tests que fallan por el selector y no por el bug.
Verificar en vivo y no codificarlo produce una app que se rompe en silencio. Hacen falta los dos.

## Modo 1 — Verificación en vivo (MCP)

Herramientas disponibles, y para qué sirve cada una:

| Herramienta | Uso real |
|---|---|
| `browser_navigate` | Abrir la ruta que verifica el criterio de aceptación |
| `browser_console_messages` | **El primer chequeo, siempre.** Un error de consola invalida la pantalla aunque se vea bien |
| `browser_take_screenshot` | Evidencia visual: adjúntala al reporte de `docs/qa/` |
| `browser_evaluate` | Aserciones sobre el DOM real: contar filas, leer el texto de un error, comprobar la URL |
| `browser_resize` | Móvil vs escritorio. El estándar es móvil primero, así que se comprueba a 375 px **antes** que a 1280 |

### Bucle de verificación

Para cada criterio de aceptación:

1. `browser_navigate` a la ruta.
2. `browser_console_messages` → **si hay `error`, se para aquí**. No se sigue verificando una
   pantalla que ya está rota; se reporta y se devuelve la tarea.
3. `browser_evaluate` con la aserción concreta del criterio. Devuelve datos, no impresiones:

   ```js
   () => ({
     filas:  document.querySelectorAll('[data-testid="row"]').length,
     url:    location.pathname + location.search,
     vacio:  !!document.querySelector('[data-testid="empty-state"]'),
     errores: [...document.querySelectorAll('[data-testid$="-error"]')].map(e => e.textContent.trim()),
   })
   ```

4. `browser_resize` a 375×667 y repite lo que dependa del layout.
5. `browser_take_screenshot` de los estados que el usuario tiene que aprobar.

Nunca concluyas "funciona" a partir de una captura. La captura es evidencia para el humano;
la aserción es `browser_evaluate`.

## Modo 2 — Spec de regresión

Cada criterio de aceptación se convierte en **un test**. Esa es la traza completa:
`STORY-003 · AC-2` → `tests/e2e/products-list.spec.js` → `test('AC-2: ...')`.

```
tests/e2e/
├── fixtures/auth.js        # login programático reutilizable
├── smoke.spec.js           # la app levanta, login funciona, ruta protegida redirige
├── auth.spec.js            # login, 401, 403, ?redirect=
└── <historia>.spec.js      # un archivo por historia
```

`playwright.config.js`: `baseURL` desde env, `webServer` levantando `npm run dev`,
`trace: 'on-first-retry'`, proyecto `chromium` (añade webkit solo si el usuario lo exige).

Con varios frontends, **un proyecto de Playwright por instancia**, cada uno con su `baseURL`:
`cliente_frontend` y `admin_frontend` no comparten puerto ni sesión.

## Reglas de escritura

- **Selectores por rol o por `data-testid`.** Nunca por clase Tailwind: las clases cambian con
  el diseño y romperían el test sin que nada esté roto de verdad.
  `page.getByRole('button', { name: 'Guardar' })` ✔ · `page.locator('.bg-primary-600')` ✘
- **Cero `waitForTimeout`.** Usa `expect(...).toBeVisible()` y esperas de red explícitas.
  El debounce de 300 ms se espera con `waitForResponse`, no con un sleep.
- **Credenciales de las fixtures del backend** (`doctrine:fixtures:load`): usuario `admin`,
  contraseña `pass_1234`, y el campo de login es **`username`**, no `email`.
- Cada test es independiente y puede correr solo. Estado compartido entre tests = tests frágiles.
- Un test por criterio, con el ID del criterio en el título.

## Cobertura mínima innegociable

1. **Smoke**: la app carga **sin errores de consola**; el login con las fixtures funciona; una
   ruta protegida sin sesión redirige a `/login?redirect=...`; el listado principal pinta filas.
2. **Auth**: petición sin token → `401`; token inválido o caducado → vuelta a `/login`;
   rol insuficiente → `/403`. (No hay refresh token en este kit: no escribas tests de refresh.)
3. **Listados**: la paginación cambia la URL y los datos; búsqueda con debounce; recargar la URL
   filtrada reproduce el estado exacto; vacío filtrado ≠ vacío sin datos.
4. **Formularios**: un `422` del backend pinta el error **en el campo correcto** (esto valida el
   contrato de `violations` de punta a punta); doble clic en submit no envía dos veces.
5. **Errores**: `500` simulado con `page.route()` muestra la vista de error con reintento.
6. **Responsive**: la pantalla principal a 375 px no desborda horizontalmente.

## Ejecución

```bash
npx playwright test                       # todo
npx playwright test tests/e2e/auth.spec.js
npx playwright test --ui                  # depuración
npx playwright show-report
```

## Al fallar

Un test rojo se diagnostica antes de tocarlo. El orden que ahorra tiempo:

1. `browser_console_messages` en esa ruta: si hay un error de JS, el fallo es del frontend y el
   test tiene razón.
2. `curl` al endpoint con el token de las fixtures: si el backend devuelve otra forma, el fallo
   es del backend o del contrato.
3. Si las dos capas responden bien, el test estaba mal escrito.

**Nunca relajes una aserción para que pase.** Si el test estaba mal, arréglalo y anota por qué
en la bitácora de la tarea; si el código está mal, se abre la tarea de corrección y el test se
queda rojo hasta entonces.
