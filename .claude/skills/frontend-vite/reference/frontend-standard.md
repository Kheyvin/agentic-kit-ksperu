# PROMPT BASE — FRONTEND HEADLESS (Vue 3 + Vite + Pinia + Axios + Tailwind CSS)

## 0. Rol y objetivo

Actúa como **Arquitecto Frontend Senior**. Vas a construir una **SPA headless** que consume una API REST (Symfony 8 + API Platform 4) autenticada con **JWT**. El código debe ser **limpio, modular, escalable y predecible**, siguiendo **Atomic Design**, **Composition API** y separación estricta de responsabilidades.

**Reglas de oro (no negociables):**
1. **Composition API + `<script setup>` siempre.** Nunca Options API.
2. **JavaScript puro con tipado vía JSDoc.** No introducir TypeScript (no está en el stack).
3. **Tailwind CSS es el único sistema de estilos.** Prohibido crear frameworks CSS propios, archivos de utilidades manuales o CSS por componente salvo excepciones documentadas (ver §10).
4. **Ningún componente llama a `axios` directamente.** Toda red pasa por `services/`.
5. **La lógica de negocio vive en `stores/` (Pinia) y `composables/`, nunca en componentes de presentación.**
6. **GSAP SOLO en landing pages / marketing.** En sistemas (ERP, CRM, dashboards, paneles) **está prohibido**: sobrecarga la navegación y degrada UX (§9).
7. **Todo import de vista/ruta es lazy** (`() => import(...)`).
8. **Nada de valores mágicos:** endpoints, claves de storage, enums → `constants/`; tokens visuales → `@theme` de Tailwind.
9. **El frontend nunca "adivina" el formato del backend:** consume exactamente el contrato de §3 y lo normaliza en un solo lugar (`services/http/normalizers.js`).

---

## 1. Stack tecnológico (fijo)

| Tecnología          | Versión | Rol |
|---------------------|---------|-----|
| Vue                 | ^3.5    | Framework UI (Composition API) |
| Vite                | ^8.0    | Build / dev server |
| Vue Router          | ^5.1    | Enrutado SPA |
| Pinia               | ^3.0    | Estado global |
| Axios               | ^1.17   | Cliente HTTP |
| **Tailwind CSS**    | ^4.x    | **Framework CSS (utility-first)** |
| **@tailwindcss/vite** | ^4.x  | Plugin oficial de integración con Vite |
| GSAP                | ^3.15   | Animaciones — **solo landings** |
| playwright-core     | ^1.60   | Smoke tests (`npm run smoke`) |

**Instalación de Tailwind (v4, sin `tailwind.config.js` salvo necesidad):**
```bash
npm install tailwindcss @tailwindcss/vite
```
```js
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
})
```

Recomendado en `devDependencies`: `prettier` + `prettier-plugin-tailwindcss` (orden determinista de clases).

---

## 2. Estructura de carpetas (obligatoria)

```
src/
├── main.js                  # Bootstrap: app, pinia, router, estilos globales
├── App.vue                  # Shell raíz: <RouterView> + error boundary (onErrorCaptured)
│
├── assets/                  # Estáticos procesados por Vite (img, fonts, svg)
│
├── styles/
│   └── main.css             # ÚNICO css global: @import "tailwindcss" + @theme (tokens)
│
├── config/
│   ├── env.js               # Lectura VALIDADA de import.meta.env (falla al boot si falta algo)
│   └── app.config.js        # Constantes de app: ITEMS_PER_PAGE, timeouts, feature flags
│
├── constants/
│   ├── api.routes.js        # Endpoints centralizados (espejo del contrato §3)
│   ├── storage.keys.js      # Claves de localStorage/sessionStorage
│   └── enums.js             # Estados, roles (MISMOS valores que el backend: ROLE_ADMIN...)
│
├── services/                # CAPA DE RED — única que conoce axios y el formato API Platform
│   ├── http/
│   │   ├── client.js        # Instancia axios: baseURL, timeout, headers Accept
│   │   ├── interceptors.js  # Request (Bearer) + Response (refresh con cola, errores)
│   │   ├── errorHandler.js  # RFC 7807 → AppError normalizado (§3.3)
│   │   └── normalizers.js   # Colecciones API Platform → { items, total } (§3.2)
│   └── modules/             # Un archivo por dominio, funciones puras de red
│       ├── auth.service.js
│       ├── user.service.js
│       └── <dominio>.service.js
│
├── stores/                  # Pinia (setup stores) — estado + orquestación de negocio
│   ├── auth.store.js
│   └── <dominio>.store.js
│
├── composables/             # Lógica reutilizable de UI/estado local
│   ├── useAsyncState.js     # { data, loading, error, execute } + AbortController
│   ├── useCollection.js     # Listados: paginación + filtros + orden + sync con URL
│   ├── useForm.js           # Valores, validación cliente, mapeo de violations 422
│   ├── useNotify.js         # Toasts (success/error/info)
│   └── useGsap.js           # SOLO landings, import dinámico de gsap
│
├── components/              # ATOMIC DESIGN (solo presentación, estilado con Tailwind)
│   ├── atoms/               # BaseButton, BaseInput, BaseBadge, BaseSpinner, BaseIcon...
│   ├── molecules/           # FormField, SearchBar, PaginationBar, CardStat...
│   ├── organisms/           # DataTable, AppNavbar, AppSidebar, LoginForm...
│   └── templates/           # Esqueletos de página con slots, sin datos
│
├── layouts/                 # AuthLayout, AdminLayout, LandingLayout, BlankLayout
│
├── views/                   # PÁGINAS mapeadas a rutas ("pages" de Atomic)
│   ├── auth/                # LoginView, ForgotPasswordView...
│   ├── errors/              # NotFoundView, ForbiddenView, ServerErrorView
│   └── <modulo>/            # <Modulo>ListView, <Modulo>DetailView, <Modulo>FormView
│
├── router/
│   ├── index.js             # createRouter + scrollBehavior
│   ├── routes.js            # Rutas lazy + meta { requiresAuth, roles, layout, title }
│   └── guards.js            # beforeEach: auth, roles, título de documento
│
└── utils/                   # Helpers PUROS, sin estado ni imports de app
    ├── date.js              # ISO 8601 UTC → formato local (Intl.DateTimeFormat)
    ├── iri.js               # Helpers de IRIs API Platform: toIri(), iriToId()
    ├── formatters.js        # moneda, números (Intl.NumberFormat)
    └── validators.js        # email, requeridos, longitudes (reutilizados por useForm)
```

**Regla de dependencias (flujo unidireccional, sin exceptiones):**
```
views → organisms → molecules → atoms
views → stores → services/modules → services/http
composables → stores | services
utils ← (cualquiera lo usa; utils no importa nada de la app)
```
Un `atom` jamás importa un store, un service ni el router. Evitar barrel files (`index.js`) para no romper tree-shaking: imports explícitos.

---

## 3. CONTRATO API (compartido con el backend — fuente de verdad)

> Esta sección existe **idéntica** en el prompt del backend. Cualquier cambio se hace en ambos.

### 3.1 Generalidades
- **Base URL:** `VITE_API_BASE_URL` (ej: `https://api.dominio.com/api`). Todo endpoint cuelga de `/api`.
- **Content negotiation:** el frontend envía `Accept: application/ld+json` para recursos API Platform y `Content-Type: application/json` en los cuerpos de escritura. Endpoints custom (login, reportes) hablan `application/json` plano.
- **Fechas:** siempre **ISO 8601 con timezone UTC** (`2026-07-13T15:00:00+00:00`). El backend nunca envía fechas locales; el frontend formatea con `utils/date.js` según locale del usuario.
- **Nombres de campos:** `camelCase` en el JSON (propiedades PHP tal cual). Nunca snake_case.
- **IDs y relaciones:** cada recurso expone `id` (numérico) y `@id` (IRI, ej: `/api/users/1`). Las **relaciones se escriben como IRIs**: `{ "category": "/api/categories/3" }`. Helpers en `utils/iri.js`.

### 3.2 Colecciones (listados)
API Platform 4 con `hydra_prefix: false`. Respuesta de `GET /api/products?page=1&itemsPerPage=20`:
```json
{
  "@context": "/api/contexts/Product",
  "@id": "/api/products",
  "member": [ { "@id": "/api/products/1", "id": 1, "name": "..." } ],
  "totalItems": 143,
  "view": { "next": "/api/products?page=2" }
}
```
- **Parámetros:** `page` (1-based), `itemsPerPage` (default 20, definido en `app.config.js` y en la config del backend — mismo valor).
- **Orden:** `?order[campo]=asc|desc`. **Filtros:** `?campo=valor` (search/exact/date según declare el backend).
- El frontend **normaliza en un único punto** (`normalizers.js`):
```js
/** @returns {{ items: object[], total: number }} */
export const normalizeCollection = (data) => ({
  items: data.member ?? [],
  total: data.totalItems ?? 0,
})
```

### 3.3 Errores (RFC 7807 — `application/problem+json`)
Todo error del backend llega con este shape (API Platform lo emite nativamente):
```json
{
  "status": 422,
  "title": "An error occurred",
  "detail": "name: Este valor no debería estar vacío.",
  "violations": [
    { "propertyPath": "name", "message": "Este valor no debería estar vacío." }
  ]
}
```
`errorHandler.js` lo transforma SIEMPRE a:
```js
/**
 * @typedef {Object} AppError
 * @property {number} status      - HTTP status (0 si es error de red)
 * @property {string} code        - 'VALIDATION' | 'UNAUTHORIZED' | 'FORBIDDEN' | 'NOT_FOUND' | 'CONFLICT' | 'SERVER' | 'NETWORK'
 * @property {string} message     - Mensaje mostrable al usuario
 * @property {Record<string,string>} [fields] - { propertyPath: message } derivado de violations
 */
```
Mapeo obligatorio: `400→VALIDATION`, `401→UNAUTHORIZED`, `403→FORBIDDEN`, `404→NOT_FOUND`, `409→CONFLICT`, `422→VALIDATION` (con `fields`), `5xx→SERVER`, sin respuesta→`NETWORK`.

### 3.4 Autenticación
- `POST /api/login_check` con `{ "email": "...", "password": "..." }` → `200 { "token": "...", "refresh_token": "..." }`. Credenciales inválidas → `401 { "code": 401, "message": "Invalid credentials." }`.
- `POST /api/token/refresh` con `{ "refresh_token": "..." }` → nuevo par `{ token, refresh_token }` (rotación). Refresh inválido/expirado → `401`.
- `GET /api/me` → perfil del usuario autenticado (id, email, roles, nombre).
- Access token: **TTL corto (~1h)**. Refresh: **TTL largo (~30 días), rotativo, revocable**.
- Toda ruta protegida exige `Authorization: Bearer <token>`.
- **Roles:** strings `ROLE_USER`, `ROLE_ADMIN`, ... idénticos en `constants/enums.js` y en el backend.

---

## 4. Atomic Design — criterios y comunicación

- **Atoms:** indivisibles, sin lógica de negocio, prefijo `Base*`. Definen su API visual por props (`variant`, `size`, `disabled`) y encapsulan las clases Tailwind (§10.2).
- **Molecules:** combinación de átomos con un propósito (`FormField` = label + input + mensaje de error, integrado con `useForm`).
- **Organisms:** secciones funcionales (**dumb por defecto**: reciben datos por props y emiten eventos; solo consumen stores si son genuinamente transversales como `AppNavbar` con `useAuthStore`).
- **Templates:** estructura de página con slots, cero datos.
- **Pages (`views/`):** orquestan — conectan stores/composables, pasan datos a organisms, leen/escriben la ruta.

**Comunicación:** `props` abajo (con `type`, `required`/`default` y `validator` cuando aplique), `emits` arriba (kebab-case, declarados con `defineEmits`). `provide/inject` solo para transversales (tema, i18n). Prohibido mutar props.

---

## 5. Capa de servicios (Axios)

### 5.1 `client.js`
```js
import axios from 'axios'
import { env } from '@/config/env'

export const httpClient = axios.create({
  baseURL: env.API_BASE_URL,
  timeout: env.API_TIMEOUT,
  headers: { Accept: 'application/ld+json', 'Content-Type': 'application/json' },
})
```

### 5.2 `interceptors.js` — comportamiento exacto
- **Request:** si `useAuthStore().accessToken` existe → inyectar `Authorization: Bearer`.
- **Response OK:** retornar `response.data` (convenio único del proyecto: los services reciben data, no response).
- **401 con sesión activa:** ejecutar refresh **una sola vez** con **cola de espera**:
```js
let refreshing = null // promesa compartida: evita N refresh simultáneos

async function onUnauthorized(originalRequest) {
  if (originalRequest._retry) return logoutAndReject()   // anti-bucle
  originalRequest._retry = true
  refreshing ??= authStore.refresh().finally(() => (refreshing = null))
  await refreshing                                        // todas las requests esperan aquí
  return httpClient(originalRequest)                      // reintento con token nuevo
}
```
  Si el refresh falla → `logout()` + redirect a `/login?redirect=<ruta actual>`.
- **403:** notificar "sin permisos" vía `useNotify` (no logout).
- **422/400/404/409/5xx/network:** delegar a `errorHandler.js` y **rechazar con `AppError`** — los stores y composables solo conocen `AppError`, nunca el error crudo de axios.
- El endpoint de refresh y el de login están **excluidos** del interceptor de 401.

### 5.3 `modules/*.service.js`
- Una función por endpoint. Reciben parámetros primitivos/DTOs, retornan data normalizada. **Sin estado, sin loading, sin toasts** (eso es de stores/composables).
- Colecciones pasan por `normalizeCollection`. Endpoints desde `constants/api.routes.js`.
```js
// product.service.js
export const productService = {
  /** @param {{ page?: number, itemsPerPage?: number, order?: object, filters?: object }} params */
  list: async (params) => normalizeCollection(await httpClient.get(API.PRODUCTS.LIST, { params: buildQuery(params) })),
  get:    (id)          => httpClient.get(API.PRODUCTS.ITEM(id)),
  create: (payload)     => httpClient.post(API.PRODUCTS.LIST, payload),
  update: (id, payload) => httpClient.patch(API.PRODUCTS.ITEM(id), payload, { headers: { 'Content-Type': 'application/merge-patch+json' } }),
  remove: (id)          => httpClient.delete(API.PRODUCTS.ITEM(id)),
}
```

---

## 6. Estado con Pinia

- **Un store por dominio**, sintaxis *setup store*. Orden interno: refs (state) → computed (getters) → funciones async (actions) → `return` explícito.
- Actions llaman a services, gestionan `loading/error` (tipo `AppError|null`), mutan estado. Sin axios directo.
- **Qué va a store vs composable:** store = estado **compartido entre vistas** (sesión, catálogos, carrito). Composable = estado **local de una vista** (un listado, un formulario). No inflar stores con estado efímero.
- **Persistencia explícita y mínima:** solo `refreshToken` y preferencias de UI, con claves de `storage.keys.js`. `accessToken` y `user` viven **en memoria**; al recargar la página, `App.vue` intenta `refresh()` con el refresh token persistido para restaurar sesión.
> *Nota de seguridad:* el patrón por defecto es access en memoria + refresh en `localStorage`. Si el proyecto exige más seguridad, migrar a cookie `httpOnly` emitida por el backend y borrar todo storage de tokens; el resto de la arquitectura no cambia.

```js
export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref(null)
  const user = ref(null)
  const loading = ref(false)
  /** @type {import('vue').Ref<AppError|null>} */
  const error = ref(null)

  const isAuthenticated = computed(() => !!accessToken.value)
  const hasRole = (role) => user.value?.roles?.includes(role) ?? false

  async function login(credentials) { /* authService.login → set tokens → fetchProfile */ }
  async function refresh() { /* usa refreshToken persistido, rota tokens */ }
  async function fetchProfile() { /* GET /api/me */ }
  function logout() { /* limpia memoria + storage + redirect lo hace el guard */ }

  return { accessToken, user, loading, error, isAuthenticated, hasRole, login, refresh, fetchProfile, logout }
})
```

---

## 7. Router (Vue Router 5)

- Rutas lazy siempre. `meta: { requiresAuth: boolean, roles?: string[], layout: string, title: string }`.
- Layout resuelto por meta en `App.vue` (componente dinámico) o por rutas anidadas — elegir UNO y documentarlo.
- **`guards.js` (beforeEach), en este orden:**
  1. Si `requiresAuth` y no autenticado → intentar restaurar sesión (refresh); si falla → `/login?redirect=to.fullPath`.
  2. Si autenticado y va a `/login` → redirect a home.
  3. Si `roles` definidos y `!roles.some(hasRole)` → `/403`.
  4. `document.title = to.meta.title + ' · ' + APP_NAME`.
- `scrollBehavior`: restaurar posición en back/forward, top en navegación nueva.
- **Rutas obligatorias:** catch-all `404`, `403`, `500`. Tras login exitoso, honrar `?redirect=`.

---

## 8. Composables (contratos exactos)

- **`useAsyncState(fn)`** → `{ data, loading, error, execute }`. Crea `AbortController` por ejecución y **cancela la anterior** si sigue viva (evita respuestas fuera de orden); aborta en `onUnmounted`.
- **`useCollection(serviceFn)`** → `{ items, total, page, itemsPerPage, filters, order, loading, error, refresh }`. **Sincroniza bidireccional con query params** de la ruta (la URL es la fuente de verdad de un listado: recargar/compartir URL reproduce el estado).
- **`useForm({ initialValues, rules })`** → `{ values, errors, submitting, validate, handleSubmit, reset, setServerErrors }`. `setServerErrors(appError.fields)` mapea las `violations` 422 por `propertyPath` directo a cada `FormField`. `handleSubmit` previene doble envío (`submitting`).
- **`useNotify()`** → `{ success, error, info }`; renderiza el organism `ToastContainer` montado en el layout.
- **Regla:** lógica repetida en ≥2 componentes → composable. Un composable no renderiza nada.

---

## 9. GSAP — política estricta

- **Permitido:** solo `views/landing/**` o proyectos tipo landing/marketing/portfolio.
- **Prohibido** en ERP, CRM, dashboards o cualquier sistema de gestión: sobrecarga la navegación, penaliza rendimiento y rompe la previsibilidad UX.
- Al iniciar el proyecto se fija `APP_TYPE = 'landing' | 'system'` en `app.config.js`. Si es `system`: **gsap no se instala ni se importa** (retirarlo de dependencies).
- Cuando aplique: import **dinámico** dentro de `useGsap.js` (nunca en `main.js`), respetar `prefers-reduced-motion` (si está activo → sin animaciones), y `kill()` de timelines/ScrollTriggers en `onUnmounted`.
- Micro-transiciones de UI en sistemas (hover, apertura de modales) se resuelven con **transiciones de Tailwind** (`transition`, `duration-*`) y `<Transition>` de Vue — nunca con GSAP.

---

## 10. Tailwind CSS — convenciones obligatorias

### 10.1 Setup y tokens
`styles/main.css` es el **único** CSS global:
```css
@import "tailwindcss";

@theme {
  /* ÚNICA fuente de verdad visual del proyecto */
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-surface: #ffffff;
  --color-danger-500: #ef4444;
  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --radius-card: 0.75rem;
}
```
- Todo color, fuente, radio o spacing custom se declara en `@theme` y se usa como utilidad (`bg-primary-600`, `rounded-card`).
- **Prohibido** hardcodear valores arbitrarios de marca en clases (`bg-[#2563eb]` ❌ → token ✅). Los valores arbitrarios (`w-[137px]`) solo para casos únicos y justificados en comentario.
- El *reset* lo aporta Preflight de Tailwind: no crear `_reset.css`.

### 10.2 Estilado de componentes
- **La reutilización de estilos se logra con componentes (atoms), no con `@apply`.** `@apply` queda restringido a estilos base de terceros o excepciones documentadas.
- Los atoms encapsulan variantes como mapas de clases:
```vue
<script setup>
const props = defineProps({
  variant: { type: String, default: 'primary', validator: (v) => v in VARIANTS },
  size: { type: String, default: 'md' },
})
const VARIANTS = {
  primary: 'bg-primary-600 text-white hover:bg-primary-500 focus-visible:ring-primary-600',
  secondary: 'bg-surface text-gray-900 ring-1 ring-gray-300 hover:bg-gray-50',
  danger: 'bg-danger-500 text-white hover:bg-danger-500/90',
}
const SIZES = { sm: 'px-3 py-1.5 text-sm', md: 'px-4 py-2 text-sm', lg: 'px-5 py-2.5 text-base' }
</script>

<template>
  <button type="button"
    class="inline-flex items-center justify-center rounded-card font-medium transition
           focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2
           disabled:pointer-events-none disabled:opacity-50"
    :class="[VARIANTS[variant], SIZES[size]]">
    <slot />
  </button>
</template>
```
- Si un combo de utilidades se repite en ≥2 sitios → **extraer atom/molecule**, no copiar la cadena de clases.
- **Mobile-first:** estilos base para móvil, `md:`/`lg:` para escalar. Breakpoints por defecto de Tailwind salvo definición en `@theme`.
- **Dark mode** (si el proyecto lo pide): estrategia por clase + variantes `dark:` desde el inicio, no como retrofit.
- Estados obligatorios en interactivos: `hover:`, `focus-visible:` (accesibilidad), `disabled:`.
- Orden de clases: automático con `prettier-plugin-tailwindcss` (layout → box → tipografía → color → estados).

---

## 11. Convenciones de código limpio

- **Componentes:** `PascalCase.vue` (atoms `Base*`). **Composables:** `useXxx.js`. **Stores:** `xxx.store.js`. **Services:** `xxx.service.js`.
- **Orden en `<script setup>`:** imports → `defineProps`/`defineEmits` → stores/composables → refs → computed → watchers → funciones → lifecycle hooks.
- **JSDoc obligatorio** en: services (params y retorno), composables (contrato), utils y props no triviales.
- Componentes < 200 líneas; si crece → dividir en molecules/organisms.
- Errores nunca silenciados: todo `catch` o propaga `AppError` o notifica al usuario.
- Sin `console.log` en commits (permitido `console.error` en `errorHandler` y error boundary).
- `config/env.js` valida al boot que existan `VITE_API_BASE_URL`, etc., y **lanza error explícito** si falta alguna (fallar rápido > fallar raro).
- Nombres de eventos emitidos en kebab-case (`@row-selected`), handlers `onXxx`/`handleXxx`.

---

## 12. Casuísticas a cubrir siempre

- **Estados de UI:** toda vista con datos implementa `loading` (skeleton/spinner), `empty` (mensaje + CTA), `error` (mensaje + retry) y `success`.
- **Auth:** login, logout, refresh con cola, restauración de sesión al recargar, expiración, `?redirect=`, protección por rol, `/403`.
- **Formularios:** validación cliente (`rules`) + servidor (`violations` 422 mapeadas por campo), disabled/submitting, prevención de doble submit, `reset`, dirty-check antes de abandonar (guard `beforeRouteLeave` en formularios largos).
- **Listados:** paginación, búsqueda con debounce (300ms), filtros, orden, sincronización con URL, estado vacío diferenciado ("sin datos" vs "sin resultados para el filtro").
- **Concurrencia:** cancelación de requests obsoletos (AbortController), última respuesta gana.
- **Red:** offline/timeout → `AppError NETWORK` + toast + opción retry.
- **Errores globales:** interceptor + `onErrorCaptured` en App.vue como error boundary + vistas de error.
- **Accesibilidad:** labels asociados, `focus-visible` en todo interactivo, roles ARIA en organisms (tabla, nav, dialog), contraste según tokens.

---

## 13. Testing (smoke)

`npm run smoke` (`scripts/smoke.mjs` con playwright-core) cubre como mínimo: la app levanta sin errores de consola, login con credenciales de fixtures funciona, ruta protegida sin sesión redirige a login, y el listado principal renderiza filas.

---

## 14. Checklist de aceptación

- [ ] Ningún componente importa `axios`; ninguna vista conoce el formato hydra/RFC 7807 (todo normalizado en `services/http`).
- [ ] Tailwind es el único sistema de estilos; tokens solo en `@theme`; cero CSS por componente sin justificación.
- [ ] Reutilización visual vía atoms, no `@apply` ni cadenas de clases duplicadas.
- [ ] Toda ruta es lazy con `meta` completo; guards de auth y rol funcionando; `?redirect=` honrado.
- [ ] Refresh de token con cola anti-bucle; sesión se restaura al recargar.
- [ ] `useForm` mapea `violations` del backend campo a campo.
- [ ] Listados sincronizados con la URL y con los 4 estados de UI.
- [ ] GSAP ausente si `APP_TYPE === 'system'`; si es landing, lazy + reduced-motion + cleanup.
- [ ] Enums/roles idénticos a los del backend.
- [ ] Smoke test en verde.
