---
name: api-contract
description: Contrato API compartido entre el backend Symfony/API Platform y la SPA Vue — formatos, colecciones, errores RFC 7807, autenticación JWT, fechas e IRIs. Úsalo siempre que se diseñe, consuma o cambie un endpoint, y ante cualquier duda de formato entre las dos capas.
---

# Contrato API — fuente de verdad

Este contrato es **idéntico** en backend y frontend. Vive en `docs/CONTRACT.md` dentro del
proyecto; esta skill es el estándar del que se parte. **Cambiarlo exige ADR + dos tareas
(backend y frontend) en el mismo lote.** Un cambio unilateral es un incidente, no un commit.

## Generalidades

- Todo cuelga de `/api`. Docs en `/api/docs`.
- Recursos API Platform en `application/ld+json`; escrituras aceptan `application/json`;
  PATCH usa `application/merge-patch+json`. Endpoints custom hablan `application/json` plano.
- **Fechas: ISO 8601 en UTC** (`2026-07-13T15:00:00+00:00`). Doctrine `datetime_immutable`.
  El backend nunca envía hora local; el frontend formatea con `utils/date.js`.
- **Campos en `camelCase`**, sin name converters. Nunca snake_case.
- Cada recurso expone `id` numérico y `@id` (IRI). **Relaciones se escriben como IRIs:**
  `{ "category": "/api/categories/3" }`.

## Colecciones

`hydra_prefix: false`, `pagination_items_per_page: 20` — **el mismo 20 en `app.config.js`**.

```json
{ "member": [ { "@id": "/api/products/1", "id": 1 } ], "totalItems": 143,
  "view": { "next": "/api/products?page=2" } }
```

Parámetros: `page` (1-based), `itemsPerPage`. Orden: `?order[campo]=asc|desc`.
Filtros declarados **explícitamente por recurso** — nunca exponer todos los campos.
El frontend normaliza en un único punto: `normalizeCollection → { items, total }`.

## Errores — RFC 7807

```json
{ "status": 422, "title": "An error occurred", "detail": "...",
  "violations": [ { "propertyPath": "name", "message": "..." } ] }
```

Mapeo obligatorio: `400` malformado · `401` sin/mal token · `403` sin permiso (Voter) ·
`404` no existe · `409` conflicto de negocio · `422` validación **siempre con `violations[]`** ·
`500` opaco en producción.

El frontend traduce a `AppError { status, code, message, fields }` con
`400→VALIDATION, 401→UNAUTHORIZED, 403→FORBIDDEN, 404→NOT_FOUND, 409→CONFLICT, 422→VALIDATION,
5xx→SERVER, sin respuesta→NETWORK`. `useForm.setServerErrors()` mapea `violations` por
`propertyPath` a cada campo del formulario: **romper ese shape rompe todos los formularios**.

## Autenticación

- `POST /api/login_check` `{email, password}` → `200 { token, refresh_token }`; inválido → `401`.
- `POST /api/token/refresh` `{refresh_token}` → nuevo par, rotativo (`single_use: true`).
- `GET /api/me` → `{ id, email, roles, fullName }`, fuente autoritativa del perfil.
- TTL: access `3600s`, refresh `2592000s` revocable en BD (logout real).
- Roles: strings idénticos en backend y en `constants/enums.js` (`ROLE_USER`, `ROLE_ADMIN`).

## Divergencia entre repositorios

Si backend y frontend viven en repos separados, nada impide que uno cambie el contrato y el
otro no se entere hasta que un formulario deje de pintar errores. Por eso existe el lock:

```bash
bash .claude/scripts/gate-contract.sh
```

Guarda el hash de `docs/CONTRACT.md` en `docs/.contract.lock`. Los dos repos deben tener el
mismo valor. Cuando cambies el contrato, el gate falla a propósito hasta que hayas escrito el
ADR, creado las dos tareas y copiado el archivo al otro repositorio.

En monorepo el gate sigue siendo útil —te avisa de que un cambio de contrato requiere ADR y
dos tareas— pero el riesgo de divergencia física desaparece.

## Al añadir un endpoint

1. Escribe la entrada en `docs/CONTRACT.md` **antes** de implementar: método, ruta, request,
   response de éxito, y los códigos de error posibles con su forma exacta.
2. Genera dos tareas hermanas que citen ese fragmento.
3. El test E2E del criterio de aceptación es lo que verifica que ambas coinciden.
