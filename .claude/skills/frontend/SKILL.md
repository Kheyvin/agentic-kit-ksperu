---
name: frontend
description: Estándar de la SPA Vue 3 + Vite + Pinia + Axios + Tailwind 4 del kit — árbol de carpetas, capa de red con AppError, composables (useCollection, useForm), Atomic Design, router con guards, cuatro estados de UI y accesibilidad básica. Úsalo al escribir o revisar .vue o .js de cualquier instancia frontend.
---

# Frontend — Vue 3 + Vite + Pinia + Tailwind 4

Composition API con `<script setup>`. JavaScript con JSDoc (TypeScript solo si la instancia se
creó con la plantilla `vue-ts`). Tailwind es el único sistema de estilos. Código y nombres en
inglés; comentarios en español.

El código canónico de la base (cliente HTTP, interceptores, `AppError`, store de auth, router,
composables, atoms, login) está en [reference/patrones.md](reference/patrones.md) y **ya existe
en `src/` de la instancia tras el bootstrap**. Antes de escribir una pieza, `grep` si ya hay una
que lo hace. Consulta la referencia por sección; no la leas entera.

## Árbol

```
src/
├── config/        env.js (valida import.meta.env al arrancar) · app.config.js (ITEMS_PER_PAGE = 20)
├── constants/     api.routes.js · enums.js (ROLE_* iguales al backend) · storage.keys.js
├── services/      http/{client,interceptors,errorHandler,normalizers}.js · modules/<dominio>.service.js
├── stores/        <dominio>.store.js — Pinia setup stores; solo estado compartido entre vistas
├── composables/   useAsyncState · useCollection · useForm · useNotify · use<LoQueSea>
├── components/    atoms/Base*.vue · molecules/ · organisms/
├── layouts/       AppLayout · AuthLayout · BlankLayout
├── views/         <modulo>/<Modulo>ListView.vue, <Modulo>FormView.vue · auth/ · errors/
├── router/        index.js · routes.js (lazy + meta) · guards.js
└── utils/         funciones puras sin imports de la app (date.js, iri.js, validators.js)
```

Dependencias en una sola dirección: `views → organisms → molecules → atoms`;
`views → stores → services/modules → services/http`; `composables → stores | services`.
Un atom nunca importa store, service ni router. Con varios backends, un archivo de rutas por
backend (`api.ventas.routes.js`, `api.admin.routes.js`).

## Red

- **Ningún componente importa `axios`** (el gate lo bloquea). Una función por endpoint en
  `services/modules/`; sin estado, sin toasts.
- El interceptor devuelve `response.data` y convierte todo error en
  `AppError { status, code, message, fields }` con `code` en `VALIDATION | UNAUTHORIZED |
  FORBIDDEN | NOT_FOUND | CONFLICT | SERVER | NETWORK`. Stores y vistas solo conocen `AppError`.
- `401` fuera del login → `logout()` y `/login?redirect=<ruta>`. **No hay refresh token**: nada
  de colas ni reintentos. El login queda excluido del interceptor: un `401` ahí se pinta en el
  formulario.
- Colecciones → `normalizeCollection(data)` → `{ items, total }`. PATCH con
  `Content-Type: application/merge-patch+json`. Las relaciones se envían como IRIs.

## Composables (contratos)

- `useAsyncState(fn)` → `{ data, loading, error, execute }`; cancela la ejecución anterior con
  `AbortController`.
- `useCollection(serviceFn, { filters })` → `{ items, total, page, itemsPerPage, filters, order,
  isFiltered, loading, error, refresh, setPage, setFilter, setOrder }`. **La URL es la fuente de
  verdad del listado**: recargar o compartir la URL reproduce el estado.
- `useForm({ initialValues, rules })` → `{ values, errors, submitting, isValid, validate,
  handleSubmit, reset, setServerErrors }`. `handleSubmit(onValid, onError)` evita el doble envío
  y mapea las `violations` 422 por `propertyPath` a `errors`.
- `useNotify()` → `{ success, error, info }`.

Lógica repetida en dos componentes → composable. Un composable no renderiza.

## Vistas

- Toda vista con datos implementa **cuatro estados**: `loading` (skeleton), `empty` (mensaje +
  acción), `error` (mensaje + reintentar) y `success`; y distingue "sin datos" de "sin resultados
  para el filtro" (`isFiltered`).
- Listados: paginación y filtros en la URL; búsqueda con debounce de 300 ms.
- Formularios: `useForm` + `FormField`; el error del servidor aparece en su campo; botón
  deshabilitado mientras `submitting`.
- Rutas lazy (`() => import(...)`) con `meta: { requiresAuth, roles?, layout, title }`.
  Guards en orden: auth → rol → título. Existen `/403` y el catch-all 404.
- Orden en `<script setup>`: imports → props/emits → stores/composables → refs → computed →
  watchers → funciones → lifecycle. Componentes por debajo de 200 líneas.
- Errores nunca silenciados: todo `catch` propaga el `AppError` o notifica.

## Estilo

- Tokens en `@theme` de `src/style.css` (`--color-primary-600`, `--radius-card`…); prohibido
  `bg-[#2563eb]`. Reutilización con atoms, no con `@apply` ni cadenas de clases copiadas.
- Móvil primero; `md:` y `lg:` para escalar. `hover:`, `focus-visible:` y `disabled:` en todo
  interactivo.
- Sin librería de animación: `transition` de Tailwind y `<Transition>` de Vue, respetando
  `prefers-reduced-motion`. GSAP solo si el usuario lo pide → skill `gsap-vue`.

## Accesibilidad mínima (en cada tarea de UI)

Un `<h1>` por vista y landmarks (`<nav>`, `<main>`) · todo lo clicable es `<button>` o `<a>`
(un `div` con `@click` no vale) · `focus-visible` visible · cada input con `<label for>` y su
error con `aria-describedby` + `aria-invalid` · el color nunca es el único portador de
significado · modales con foco atrapado y cierre con Escape · toasts en `aria-live` ·
contraste 4.5:1 en texto · objetivos táctiles de 44 px.

## Mockup (opcional)

Si la tarea trae `mockup:` con un HTML en `docs/mockups/`, impleméntalo tal cual. Si no lo
trae, diseña directamente en Vue con los atoms existentes: no generes mockups por tu cuenta.

## Antes de cerrar

`bash .claude/scripts/gate-frontend.sh <instancia>` en verde (compila con Vite y comprueba la
capa de red). A mano: los cuatro estados, el `401` redirige con `?redirect=`, y `npm run dev`
abre la vista sin errores de consola.
