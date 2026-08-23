---
name: frontend-vite
description: Estándar de SPA headless Vue 3 + Vite + Pinia + Axios + Tailwind — Atomic Design, capa de servicios, stores, composables, router con guards y convenciones Tailwind. Úsalo al escribir o revisar cualquier .vue o .js del proyecto SPA.
---

# Frontend headless — Vue 3 + Vite + Pinia + Tailwind

El estándar completo está en `reference/frontend-standard.md`. **Léelo entero antes de la
primera tarea de frontend de una sesión.** Esto es el resumen operativo.

## Reglas de oro

1. Composition API + `<script setup>` siempre. Nunca Options API. Nunca TypeScript: JS + JSDoc.
2. **Ningún componente importa `axios`.** Toda red pasa por `services/`.
3. Lógica de negocio en `stores/` (Pinia) y `composables/`, jamás en componentes de presentación.
4. Tailwind es el único sistema de estilos. Tokens en `@theme`; prohibido `bg-[#2563eb]`.
   Reutilización visual vía **atoms**, no vía `@apply` ni cadenas de clases copiadas.
5. Todo import de vista es lazy: `() => import(...)`.
6. Endpoints, claves de storage y enums → `constants/`. Cero valores mágicos.
7. GSAP **solo en landings**. Si `APP_TYPE === 'system'`, ni se instala.
8. El frontend nunca adivina el formato del backend: normaliza en `services/http/normalizers.js`.

## Dependencias (dirección única)

```
views → organisms → molecules → atoms
views → stores → services/modules → services/http
composables → stores | services
utils ← todos; utils no importa nada de la app
```

Un atom jamás importa un store, un service ni el router.

## Contratos exactos de composables

- `useAsyncState(fn)` → `{ data, loading, error, execute }` con `AbortController` por ejecución.
- `useCollection(serviceFn)` → sincronización **bidireccional con query params**: recargar o
  compartir la URL reproduce el estado del listado.
- `useForm({initialValues, rules})` → `setServerErrors(appError.fields)` mapea las `violations`
  422 campo a campo; `handleSubmit` previene doble envío.
- `useNotify()` → `{ success, error, info }`.

## Los cuatro estados

Toda vista con datos implementa `loading` (skeleton), `empty` (mensaje + CTA), `error`
(mensaje + retry) y `success`. Y el vacío diferenciado: "sin datos" ≠ "sin resultados para el
filtro". Esto no es opcional ni se deja "para después".

## Antes de cerrar una tarea de frontend

```bash
bash .claude/scripts/gate-frontend.sh
```

Además, a mano: refresh de token con cola anti-bucle intacto, guards de auth y rol, `?redirect=`
honrado, y componentes por debajo de 200 líneas.
