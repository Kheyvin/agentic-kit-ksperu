---
name: qa-playwright
description: Escribir y ejecutar tests end-to-end con Playwright contra la SPA y la API — smoke, flujos de autenticación, listados, formularios y estados de error. Úsalo al verificar criterios de aceptación de una historia, al crear specs E2E o al diagnosticar un fallo de test.
---

# QA end-to-end con Playwright

Cada criterio de aceptación de una historia se convierte en **un test**. Esa es la traza
completa: `STORY-003 · AC-2` → `tests/e2e/products-list.spec.js` → `test('AC-2: ...')`.

## Estructura

```
tests/e2e/
├── fixtures/auth.js        # login programático reutilizable
├── smoke.spec.js           # la app levanta, login funciona, ruta protegida redirige
├── auth.spec.js            # login, refresh, expiración, 403, ?redirect=
└── <historia>.spec.js      # un archivo por historia
```

`playwright.config.js`: `baseURL` desde env, `webServer` levantando `npm run dev`,
`trace: 'on-first-retry'`, proyecto `chromium` (añade webkit solo si el cliente lo exige).

## Reglas de escritura

- **Selectores por rol o por `data-testid`.** Nunca por clase Tailwind: las clases cambian con
  el diseño y romperían el test sin que nada esté roto de verdad.
  `page.getByRole('button', { name: 'Guardar' })` ✔ · `page.locator('.bg-primary-600')` ✘
- **Cero `waitForTimeout`.** Usa `expect(...).toBeVisible()` y esperas de red explícitas.
  El debounce de 300 ms se espera con `waitForResponse`, no con un sleep.
- **Credenciales de las fixtures del backend** (`doctrine:fixtures:load`), nunca datos reales.
- Cada test es independiente y puede correr solo. Estado compartido entre tests = tests frágiles.
- Un test por criterio, nombrado con el ID del criterio en el título.

## Cobertura mínima innegociable

1. **Smoke**: la app carga sin errores de consola; el login con fixtures funciona; una ruta
   protegida sin sesión redirige a `/login?redirect=...`; el listado principal pinta filas.
2. **Auth**: token expirado dispara refresh y la petición se reintenta sola; refresh inválido
   hace logout; rol insuficiente lleva a `/403`.
3. **Listados**: paginación cambia la URL y los datos; búsqueda con debounce; recargar la URL
   filtrada reproduce el estado exacto; vacío filtrado ≠ vacío sin datos.
4. **Formularios**: un `422` del backend pinta el error **en el campo correcto** (esto valida el
   contrato de `violations` de punta a punta); doble clic en submit no envía dos veces.
5. **Errores**: 500 simulado con `page.route()` muestra la vista de error con retry.

## Ejecución

```bash
npx playwright test                       # todo
npx playwright test tests/e2e/auth.spec.js
npx playwright test --ui                  # depuración
npx playwright show-report
```

## Al fallar

Un test rojo se diagnostica antes de tocarlo: lee la traza, identifica si falla el frontend,
el backend o el propio test. **Nunca relajes una aserción para que pase.** Si el test estaba
mal escrito, arréglalo y anota por qué en la bitácora de la tarea; si el código está mal, abre
la tarea de corrección.
