# Patrones de referencia — frontend

Código canónico de la base. El bootstrap lo crea en `src/`; después se consulta por sección
para escribir piezas nuevas con la misma forma. Vue 3.5 · Vite · Vue Router · Pinia · Axios · Tailwind 4.

## 1. Configuración y constantes

```js
// src/config/env.js — falla al arrancar si falta algo, no tres pantallas después
const required = ['VITE_API_BASE_URL']
for (const key of required) {
  if (!import.meta.env[key]) throw new Error(`Falta la variable de entorno ${key} (revisa .env)`)
}
export const env = Object.freeze({
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL,          // http://localhost:8000/api
  API_TIMEOUT: Number(import.meta.env.VITE_API_TIMEOUT ?? 15000),
  APP_NAME: import.meta.env.VITE_APP_NAME ?? 'App',
})
```

```js
// src/config/app.config.js
export const APP = Object.freeze({ ITEMS_PER_PAGE: 20, SEARCH_DEBOUNCE_MS: 300 })

// src/constants/api.routes.js — espejo del contrato; baseURL ya incluye /api
export const API = Object.freeze({
  AUTH: { LOGIN: '/login_check', ME: '/me' },
  // PRODUCTS: { LIST: '/products', ITEM: (id) => `/products/${id}` },
})

// src/constants/enums.js — mismos strings que el backend
export const ROLES = Object.freeze({ USER: 'ROLE_USER', ADMIN: 'ROLE_ADMIN' })

// src/constants/storage.keys.js
export const STORAGE = Object.freeze({ TOKEN: 'app.token' })
```

`vite.config.js` con el alias `@`:

```js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
})
```

## 2. Capa de red

```js
// src/services/http/client.js
import axios from 'axios'
import { env } from '@/config/env'

export const httpClient = axios.create({
  baseURL: env.API_BASE_URL,
  timeout: env.API_TIMEOUT,
  headers: { Accept: 'application/ld+json', 'Content-Type': 'application/json' },
})
```

```js
// src/services/http/errorHandler.js
/**
 * @typedef {Object} AppError
 * @property {boolean} isAppError
 * @property {number} status                 0 si no hubo respuesta
 * @property {'VALIDATION'|'UNAUTHORIZED'|'FORBIDDEN'|'NOT_FOUND'|'CONFLICT'|'SERVER'|'NETWORK'} code
 * @property {string} message                mostrable al usuario
 * @property {Record<string,string>} fields  propertyPath → mensaje (de violations 422)
 */
const CODES = { 400: 'VALIDATION', 401: 'UNAUTHORIZED', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 409: 'CONFLICT', 422: 'VALIDATION' }
const MESSAGES = {
  VALIDATION: 'Revisa los campos marcados.',
  UNAUTHORIZED: 'Tu sesión ha caducado.',
  FORBIDDEN: 'No tienes permiso para esta acción.',
  NOT_FOUND: 'No se ha encontrado.',
  CONFLICT: 'La operación entra en conflicto con el estado actual.',
  SERVER: 'Error del servidor. Inténtalo de nuevo.',
  NETWORK: 'Sin conexión con el servidor.',
}

/** @param {any} error  error de axios (o AppError ya convertido) @returns {AppError} */
export function toAppError(error) {
  if (error?.isAppError) return error
  const res = error?.response
  if (!res) return make(0, 'NETWORK')
  const code = CODES[res.status] ?? (res.status >= 500 ? 'SERVER' : 'VALIDATION')
  const fields = {}
  for (const v of res.data?.violations ?? []) fields[v.propertyPath] ??= v.message
  const detail = res.status === 422 || res.status >= 500 ? null : res.data?.detail || res.data?.message
  return make(res.status, code, detail || MESSAGES[code], fields)
}

function make(status, code, message = MESSAGES[code], fields = {}) {
  return { isAppError: true, status, code, message, fields }
}
```

```js
// src/services/http/normalizers.js
/** Colección API Platform (hydra_prefix: false) → { items, total } */
export const normalizeCollection = (data) => ({ items: data?.member ?? [], total: data?.totalItems ?? 0 })
```

```js
// src/services/http/interceptors.js — se instala en main.js tras pinia y router
import { httpClient } from './client'
import { toAppError } from './errorHandler'
import { useAuthStore } from '@/stores/auth.store'
import { API } from '@/constants/api.routes'
import router from '@/router'

export function installInterceptors() {
  httpClient.interceptors.request.use((config) => {
    const { accessToken } = useAuthStore()
    if (accessToken) config.headers.Authorization = `Bearer ${accessToken}`
    return config
  })
  httpClient.interceptors.response.use(
    (response) => response.data,
    (error) => {
      const appError = toAppError(error)
      const isLogin = error.config?.url === API.AUTH.LOGIN
      if (appError.status === 401 && !isLogin) {
        useAuthStore().logout()   // sin refresh token no hay nada que reintentar
        const redirect = router.currentRoute.value.fullPath
        if (!redirect.startsWith('/login')) router.push({ path: '/login', query: { redirect } })
      }
      return Promise.reject(appError)
    },
  )
}
```

```js
// src/services/modules/auth.service.js — una función por endpoint, sin estado
import { httpClient } from '@/services/http/client'
import { API } from '@/constants/api.routes'

export const authService = {
  /** @param {{username: string, password: string}} credentials @returns {Promise<{token: string}>} */
  login: (credentials) => httpClient.post(API.AUTH.LOGIN, credentials, { headers: { Accept: 'application/json' } }),
  /** @returns {Promise<{id: number, username: string, roles: string[]}>} */
  me: () => httpClient.get(API.AUTH.ME),
}

// Un service de dominio típico:
// list:   (params, signal) => httpClient.get(API.PRODUCTS.LIST, { params, signal }).then(normalizeCollection),
// get:    (id) => httpClient.get(API.PRODUCTS.ITEM(id)),
// create: (payload) => httpClient.post(API.PRODUCTS.LIST, payload),
// update: (id, payload) => httpClient.patch(API.PRODUCTS.ITEM(id), payload, { headers: { 'Content-Type': 'application/merge-patch+json' } }),
// remove: (id) => httpClient.delete(API.PRODUCTS.ITEM(id)),
// axios serializa { order: { name: 'asc' } } como order[name]=asc, que es lo que espera API Platform.
```

## 3. Store de autenticación

```js
// src/stores/auth.store.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authService } from '@/services/modules/auth.service'
import { STORAGE } from '@/constants/storage.keys'

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref(localStorage.getItem(STORAGE.TOKEN))
  const user = ref(null)          // en memoria; se restaura con fetchProfile() al recargar
  const loading = ref(false)
  /** @type {import('vue').Ref<import('@/services/http/errorHandler').AppError|null>} */
  const error = ref(null)

  const isAuthenticated = computed(() => !!accessToken.value)
  const hasRole = (role) => user.value?.roles?.includes(role) ?? false

  /** @param {{username: string, password: string}} credentials */
  async function login(credentials) {
    loading.value = true
    error.value = null
    try {
      const { token } = await authService.login(credentials)
      accessToken.value = token
      localStorage.setItem(STORAGE.TOKEN, token)
      await fetchProfile()
    } catch (e) {
      error.value = e
      throw e
    } finally {
      loading.value = false
    }
  }
  async function fetchProfile() { user.value = await authService.me() }
  function logout() {
    accessToken.value = null
    user.value = null
    localStorage.removeItem(STORAGE.TOKEN)
  }

  return { accessToken, user, loading, error, isAuthenticated, hasRole, login, fetchProfile, logout }
})
```

## 4. Router

```js
// src/router/routes.js — todo lazy, meta completo
export const routes = [
  { path: '/login', name: 'login', component: () => import('@/views/auth/LoginView.vue'), meta: { requiresAuth: false, layout: 'auth', title: 'Iniciar sesión' } },
  { path: '/', name: 'home', component: () => import('@/views/HomeView.vue'), meta: { requiresAuth: true, layout: 'app', title: 'Inicio' } },
  { path: '/403', name: 'forbidden', component: () => import('@/views/errors/ForbiddenView.vue'), meta: { requiresAuth: false, layout: 'blank', title: 'Sin permiso' } },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/errors/NotFoundView.vue'), meta: { requiresAuth: false, layout: 'blank', title: 'No encontrado' } },
]
```

```js
// src/router/guards.js
import { useAuthStore } from '@/stores/auth.store'
import { env } from '@/config/env'

export function installGuards(router) {
  router.beforeEach(async (to) => {
    const auth = useAuthStore()
    if (to.meta.requiresAuth) {
      if (auth.isAuthenticated && !auth.user) {
        try { await auth.fetchProfile() } catch { /* el interceptor ya limpió la sesión */ }
      }
      if (!auth.isAuthenticated) return { path: '/login', query: { redirect: to.fullPath } }
      if (to.meta.roles?.length && !to.meta.roles.some(auth.hasRole)) return { path: '/403' }
    }
    if (to.path === '/login' && auth.isAuthenticated) return { path: '/' }
    return true
  })
  router.afterEach((to) => {
    document.title = to.meta.title ? `${to.meta.title} · ${env.APP_NAME}` : env.APP_NAME
  })
}
```

```js
// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { routes } from './routes'
import { installGuards } from './guards'

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: (to, from, saved) => saved ?? { top: 0 },
})
installGuards(router)
export default router
```

```js
// src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { installInterceptors } from './services/http/interceptors'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
installInterceptors()
app.mount('#app')
```

```vue
<!-- src/App.vue — layout resuelto por meta -->
<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'
import AuthLayout from '@/layouts/AuthLayout.vue'
import BlankLayout from '@/layouts/BlankLayout.vue'
import ToastContainer from '@/components/organisms/ToastContainer.vue'

const LAYOUTS = { app: AppLayout, auth: AuthLayout, blank: BlankLayout }
const route = useRoute()
const layout = computed(() => LAYOUTS[route.meta.layout] ?? BlankLayout)
</script>

<template>
  <component :is="layout"><RouterView /></component>
  <ToastContainer />
</template>
```

Cada layout es un componente con `<slot />` (`AppLayout` con `<AppNavbar />` + `<main>`).

## 5. Composables

```js
// src/composables/useAsyncState.js
import { ref, onUnmounted } from 'vue'

/** @param {(signal: AbortSignal, ...args: any[]) => Promise<any>} fn */
export function useAsyncState(fn) {
  const data = ref(null)
  const loading = ref(false)
  const error = ref(null)
  let controller = null

  async function execute(...args) {
    controller?.abort()
    controller = new AbortController()
    const current = controller
    loading.value = true
    error.value = null
    try {
      const result = await fn(current.signal, ...args)
      if (!current.signal.aborted) data.value = result
      return result
    } catch (e) {
      if (!current.signal.aborted) error.value = e
    } finally {
      if (!current.signal.aborted) loading.value = false
    }
  }
  onUnmounted(() => controller?.abort())
  return { data, loading, error, execute }
}
```

```js
// src/composables/useCollection.js — la URL es la fuente de verdad del listado
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { APP } from '@/config/app.config'
import { useAsyncState } from './useAsyncState'

/**
 * @param {(params: object, signal: AbortSignal) => Promise<{items: object[], total: number}>} serviceFn
 * @param {{ filters?: string[] }} options  nombres de filtro admitidos en la query (?name=silla)
 */
export function useCollection(serviceFn, { filters: filterKeys = [] } = {}) {
  const route = useRoute()
  const router = useRouter()

  const page = computed(() => Number(route.query.page ?? 1))
  const itemsPerPage = computed(() => Number(route.query.itemsPerPage ?? APP.ITEMS_PER_PAGE))
  const order = computed(() => {
    const [field, dir] = String(route.query.order ?? '').split(':')
    return field ? { [field]: dir || 'asc' } : {}
  })
  const filters = computed(() =>
    Object.fromEntries(filterKeys.filter((k) => route.query[k] != null && route.query[k] !== '').map((k) => [k, route.query[k]])),
  )
  const { data, loading, error, execute } = useAsyncState((signal) =>
    serviceFn({ page: page.value, itemsPerPage: itemsPerPage.value, order: order.value, ...filters.value }, signal),
  )
  const items = computed(() => data.value?.items ?? [])
  const total = computed(() => data.value?.total ?? 0)
  const isFiltered = computed(() => Object.keys(filters.value).length > 0)

  const setQuery = (patch) => router.push({ query: { ...route.query, ...patch } })
  const setPage = (p) => setQuery({ page: p })
  const setFilter = (key, value) => setQuery({ [key]: value || undefined, page: undefined })
  const setOrder = (field, dir = 'asc') => setQuery({ order: `${field}:${dir}` })

  watch(() => route.query, () => execute(), { immediate: true, deep: true })

  return { items, total, page, itemsPerPage, filters, order, isFiltered, loading, error, refresh: execute, setPage, setFilter, setOrder }
}
```

```js
// src/composables/useForm.js
import { reactive, ref, computed } from 'vue'

/** @param {{ initialValues: object, rules?: Record<string, ((value: any, values: object) => true|string)[]> }} options */
export function useForm({ initialValues, rules = {} }) {
  const values = reactive({ ...initialValues })
  const errors = reactive({})
  const submitting = ref(false)
  const isValid = computed(() => Object.keys(errors).length === 0)

  function clearErrors() { for (const k of Object.keys(errors)) delete errors[k] }
  function validate() {
    clearErrors()
    for (const [field, checks] of Object.entries(rules)) {
      for (const check of checks) {
        const result = check(values[field], values)
        if (result !== true) { errors[field] = result; break }
      }
    }
    return isValid.value
  }
  /** @param {Record<string,string>} fields  AppError.fields (violations por propertyPath) */
  function setServerErrors(fields = {}) { Object.assign(errors, fields) }
  function reset() { Object.assign(values, initialValues); clearErrors() }
  /** Valida, evita el doble envío y mapea las violations 422 al campo. onError recibe el AppError restante. */
  function handleSubmit(onValid, onError = () => {}) {
    return async () => {
      if (submitting.value || !validate()) return
      submitting.value = true
      try {
        await onValid({ ...values })
      } catch (e) {
        if (e?.fields && Object.keys(e.fields).length) setServerErrors(e.fields)
        else onError(e)
      } finally {
        submitting.value = false
      }
    }
  }
  return { values, errors, submitting, isValid, validate, handleSubmit, reset, setServerErrors }
}
```

```js
// src/composables/useNotify.js — estado de módulo: un solo listado de toasts para toda la app
import { ref } from 'vue'

const toasts = ref([])
let seq = 0
function push(type, message, timeout = 4000) {
  const id = ++seq
  toasts.value.push({ id, type, message })
  if (timeout) setTimeout(() => dismiss(id), timeout)
}
function dismiss(id) { toasts.value = toasts.value.filter((t) => t.id !== id) }

export function useNotify() {
  return { toasts, dismiss, success: (m) => push('success', m), error: (m) => push('error', m, 6000), info: (m) => push('info', m) }
}
```

```js
// src/utils/validators.js — reglas para useForm
export const required = (msg = 'Obligatorio') => (v) => (v !== null && v !== undefined && String(v).trim() !== '') || msg
export const minLength = (n, msg = `Mínimo ${n} caracteres`) => (v) => (!v || String(v).length >= n) || msg
```

## 6. Estilo y atoms

```css
/* src/style.css — único CSS global */
@import 'tailwindcss';

@theme {
  --color-primary-500: #3b82f6;
  --color-primary-600: #2563eb;
  --color-danger-500: #ef4444;
  --color-surface: #ffffff;
  --radius-card: 0.75rem;
  --font-sans: 'Inter', ui-sans-serif, system-ui, sans-serif;
}
```

```vue
<!-- src/components/atoms/BaseButton.vue -->
<script setup>
const VARIANTS = {
  primary: 'bg-primary-600 text-white hover:bg-primary-500 focus-visible:ring-primary-600',
  secondary: 'bg-surface text-gray-900 ring-1 ring-gray-300 hover:bg-gray-50 focus-visible:ring-gray-400',
  danger: 'bg-danger-500 text-white hover:bg-danger-500/90 focus-visible:ring-danger-500',
}
const SIZES = { sm: 'px-3 py-1.5 text-sm', md: 'px-4 py-2 text-sm', lg: 'px-5 py-2.5 text-base' }
defineProps({
  type: { type: String, default: 'button' },
  variant: { type: String, default: 'primary', validator: (v) => v in VARIANTS },
  size: { type: String, default: 'md', validator: (v) => v in SIZES },
})
</script>

<template>
  <button
    :type="type"
    class="inline-flex min-h-11 items-center justify-center rounded-card font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
    :class="[VARIANTS[variant], SIZES[size]]"
  >
    <slot />
  </button>
</template>
```

```vue
<!-- src/components/atoms/BaseInput.vue -->
<script setup>
defineProps({
  id: { type: String, required: true },
  type: { type: String, default: 'text' },
  invalid: { type: Boolean, default: false },
  describedby: { type: String, default: undefined },
})
const model = defineModel({ type: [String, Number], default: '' })
</script>

<template>
  <input
    :id="id"
    v-model="model"
    :type="type"
    :aria-invalid="invalid || undefined"
    :aria-describedby="describedby"
    class="w-full rounded-card border px-3 py-2 text-sm transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-600 disabled:opacity-50"
    :class="invalid ? 'border-danger-500' : 'border-gray-300'"
  />
</template>
```

```vue
<!-- src/components/molecules/FormField.vue — label + control + error accesible -->
<script setup>
defineProps({
  id: { type: String, required: true },
  label: { type: String, required: true },
  error: { type: String, default: '' },
  required: { type: Boolean, default: false },
})
</script>

<template>
  <div class="flex flex-col gap-1">
    <label :for="id" class="text-sm font-medium text-gray-900">
      {{ label }}<span v-if="required" aria-hidden="true"> *</span>
    </label>
    <slot :id="id" :invalid="!!error" :describedby="error ? `${id}-error` : undefined" />
    <p v-if="error" :id="`${id}-error`" class="text-sm text-danger-500" role="alert">{{ error }}</p>
  </div>
</template>
```

```vue
<!-- src/components/organisms/ToastContainer.vue -->
<script setup>
import { useNotify } from '@/composables/useNotify'
const { toasts, dismiss } = useNotify()
const STYLES = { success: 'bg-green-600', error: 'bg-danger-500', info: 'bg-gray-800' }
</script>

<template>
  <div class="fixed right-4 bottom-4 z-50 flex flex-col gap-2" aria-live="polite">
    <div v-for="t in toasts" :key="t.id" role="status" class="flex items-center gap-3 rounded-card px-4 py-3 text-sm text-white shadow" :class="STYLES[t.type]">
      <span>{{ t.message }}</span>
      <button type="button" class="opacity-80 hover:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white" aria-label="Cerrar" @click="dismiss(t.id)">×</button>
    </div>
  </div>
</template>
```

## 7. Vista de login (formulario + 401 en el campo + redirect)

```vue
<!-- src/views/auth/LoginView.vue -->
<script setup>
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth.store'
import { useForm } from '@/composables/useForm'
import { required } from '@/utils/validators'
import FormField from '@/components/molecules/FormField.vue'
import BaseInput from '@/components/atoms/BaseInput.vue'
import BaseButton from '@/components/atoms/BaseButton.vue'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const { values, errors, submitting, handleSubmit } = useForm({
  initialValues: { username: '', password: '' },
  rules: { username: [required()], password: [required()] },
})
const submit = handleSubmit(
  async (data) => {
    await auth.login(data)
    router.push(String(route.query.redirect ?? '/'))
  },
  (e) => { errors.password = e.status === 401 ? 'Usuario o contraseña incorrectos.' : e.message },
)
</script>

<template>
  <main class="mx-auto flex min-h-screen max-w-sm flex-col justify-center gap-6 p-6">
    <h1 class="text-2xl font-semibold">Iniciar sesión</h1>
    <form class="flex flex-col gap-4" novalidate @submit.prevent="submit">
      <FormField id="username" label="Usuario" :error="errors.username" required v-slot="field">
        <BaseInput v-bind="field" v-model="values.username" autocomplete="username" />
      </FormField>
      <FormField id="password" label="Contraseña" :error="errors.password" required v-slot="field">
        <BaseInput v-bind="field" v-model="values.password" type="password" autocomplete="current-password" />
      </FormField>
      <BaseButton type="submit" :disabled="submitting">Entrar</BaseButton>
    </form>
  </main>
</template>
```

## 8. Vista de listado (cuatro estados, URL como estado)

```vue
<script setup>
import { useCollection } from '@/composables/useCollection'
import { productService } from '@/services/modules/product.service'
const { items, total, page, isFiltered, loading, error, refresh, setPage, setFilter } = useCollection(productService.list, { filters: ['name', 'status'] })
</script>

<template>
  <section>
    <h1 class="text-2xl font-semibold">Productos</h1>
    <SearchBar @search="(q) => setFilter('name', q)" />                     <!-- debounce 300 ms dentro -->
    <p v-if="loading" aria-busy="true">Cargando…</p>                        <!-- o skeleton -->
    <ErrorState v-else-if="error" :message="error.message" @retry="refresh" />
    <EmptyState v-else-if="!items.length && isFiltered" title="Sin resultados para el filtro" />
    <EmptyState v-else-if="!items.length" title="Aún no hay productos" cta="Crear el primero" />
    <ProductsTable v-else :items="items" />
    <PaginationBar :page="page" :total="total" @change="setPage" />
  </section>
</template>
```

## 9. Playwright (config mínima)

```js
// playwright.config.js
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: 'tests/e2e',
  use: { baseURL: process.env.BASE_URL ?? 'http://localhost:5173', trace: 'on-first-retry' },
  webServer: { command: 'npm run dev', url: 'http://localhost:5173', reuseExistingServer: true },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
})
```

```js
// tests/e2e/smoke.spec.js — requiere el backend arrancado con las fixtures
import { test, expect } from '@playwright/test'

test('carga sin errores de consola y protege la home', async ({ page }) => {
  const errors = []
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()))
  await page.goto('/')
  await expect(page).toHaveURL(/\/login\?redirect=/)
  expect(errors).toEqual([])
})

test('login con las fixtures', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Usuario').fill('admin')
  await page.getByLabel('Contraseña').fill('pass_1234')
  await page.getByRole('button', { name: 'Entrar' }).click()
  await expect(page).toHaveURL('/')
})
```
