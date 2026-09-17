# Receta de bootstrap — frontend Vite + Vue 3

Parámetros que recibes: la **carpeta** de la instancia (`frontend` o `<nombre>_frontend`), la
**plantilla** (`vue` por defecto; `vue-ts` si el usuario la pidió) y la **URL del backend** que
consume (por defecto `http://localhost:8000/api`). Ejecuta desde la raíz del repositorio.
Criterio de terminado: el gate en verde y `npm run dev` abre `/login` sin errores de consola.

## 1. Proyecto y dependencias

```bash
npm create vite@latest <dir> -- --template <plantilla>
cd <dir>
npm install
npm install axios vue-router pinia tailwindcss @tailwindcss/vite
npm install -D @playwright/test
npx playwright install chromium
```

## 2. Configuración

- `vite.config.js`: plugin `tailwindcss()` y alias `@` (sección 1 de `patrones.md`).
- `src/style.css`: sustituye el contenido de la plantilla por `@import 'tailwindcss'` + `@theme`
  (sección 6). Borra `src/assets/*.css` y los componentes de demo de la plantilla
  (`HelloWorld.vue`, etc.).
- `.env`:

```dotenv
VITE_API_BASE_URL=http://localhost:8000/api
VITE_APP_NAME=<Proyecto>
```

- `.gitignore`: añade `test-results/` y `playwright-report/`.

## 3. Base del kit (todo desde `patrones.md`, con la misma forma)

| Pieza | Archivos |
|---|---|
| Config y constantes | `src/config/env.js`, `src/config/app.config.js`, `src/constants/{api.routes,enums,storage.keys}.js` |
| Red | `src/services/http/{client,errorHandler,normalizers,interceptors}.js`, `src/services/modules/auth.service.js` |
| Estado | `src/stores/auth.store.js` |
| Composables | `src/composables/{useAsyncState,useCollection,useForm,useNotify}.js`, `src/utils/validators.js` |
| Atoms y molecules | `src/components/atoms/{BaseButton,BaseInput,BaseSpinner}.vue`, `src/components/molecules/FormField.vue` |
| Organisms y layouts | `src/components/organisms/{ToastContainer,AppNavbar}.vue`, `src/layouts/{AppLayout,AuthLayout,BlankLayout}.vue` |
| Router y vistas | `src/router/{index,routes,guards}.js`, `src/views/auth/LoginView.vue`, `src/views/HomeView.vue`, `src/views/errors/{NotFoundView,ForbiddenView}.vue` |
| Arranque | `src/main.js`, `src/App.vue` |
| E2E | `playwright.config.js`, `tests/e2e/smoke.spec.js` |

`AppNavbar` muestra el nombre de la app, el `username` y un botón "Salir" que llama a
`logout()` y navega a `/login`. `HomeView` es un `<h1>` con un saludo: existe para que el smoke
tenga destino. Con `vue-ts`, mismos archivos con extensión `.ts` y tipos mínimos.

## 4. Verificación

```bash
npm run dev            # anota el puerto (5173, o el siguiente libre con varios frontends)
```

Abre `/` → debe redirigir a `/login?redirect=%2F` sin errores de consola. Con el backend
arrancado y sus fixtures, `admin` / `pass_1234` entra y muestra la home.

```bash
cd .. && bash .claude/scripts/gate-frontend.sh <dir>
```

Verde antes de devolver el control. En la respuesta: puerto real, resultado del gate y cualquier
desviación de esta receta. `npx playwright test` se corre en `/pruebas`, no aquí.
