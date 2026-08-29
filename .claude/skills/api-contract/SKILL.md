---
name: api-contract
description: Contrato API compartido entre un backend Symfony/API Platform y la SPA Vue que lo consume — formatos, colecciones, errores RFC 7807, autenticación JWT con username, fechas e IRIs. Úsalo siempre que se diseñe, consuma o cambie un endpoint, y ante cualquier duda de formato entre las dos capas.
---

# Contrato API — fuente de verdad

**Un contrato por instancia de backend**, en `docs/contracts/<instancia>.md`:

```
docs/contracts/ventas_backend.md     ← lo consume cliente_frontend
docs/contracts/admin_backend.md      ← lo consume admin_frontend
docs/contracts/*.lock                ← hash vigilado por gate-contract.sh
```

Dos backends son **dos contratos independientes**. Que `ventas_backend` cambie la forma de sus
errores no autoriza a cambiar la de `admin_backend`, y al revés. Cuando un frontend consume dos
backends, cita en cada tarea **de qué contrato** viene cada endpoint.

Esta skill es el estándar del que se parte; el archivo del proyecto es lo vinculante.
**Cambiarlo exige ADR + una tarea de backend y otra de frontend en el mismo lote.** Un cambio
unilateral es un incidente, no un commit.

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

Mapeo obligatorio: `400` malformado · `401` sin token o token inválido · `403` sin permiso
(Voter) · `404` no existe · `409` conflicto de negocio · `422` validación **siempre con
`violations[]`** · `500` sin detalle interno.

El frontend traduce a `AppError { status, code, message, fields }` con
`400→VALIDATION, 401→UNAUTHORIZED, 403→FORBIDDEN, 404→NOT_FOUND, 409→CONFLICT, 422→VALIDATION,
5xx→SERVER, sin respuesta→NETWORK`. `useForm.setServerErrors()` mapea `violations` por
`propertyPath` a cada campo del formulario: **romper ese shape rompe todos los formularios**.

## Autenticación — JWT con `username`

El identificador de login es **`username`**, no `email`. Es lo que genera `make:user` en el
bootstrap y lo que declara `username_path: username` en
`config/packages/lexik_jwt_authentication.yaml`. Un frontend que envíe `email` recibe `401` sin
explicación útil, y es el error de integración que más tiempo cuesta encontrar.

- `POST /api/login_check` `{ "username": "...", "password": "..." }` → `200 { "token": "..." }`.
  Credenciales inválidas → `401`, con mensaje genérico que no revela si el usuario existe.
- `GET /api/me` → `{ id, username, roles }`, fuente autoritativa del perfil.
- El token se manda en `Authorization: Bearer <token>`.
- TTL del access token: `3600s`.
- Roles: strings idénticos en backend y en `constants/enums.js` (`ROLE_USER`, `ROLE_ADMIN`).

**No hay refresh token.** Cuando el token caduca, la petición devuelve `401`, el frontend limpia
la sesión y manda a `/login?redirect=<ruta actual>`. No implementes colas de reintento, rotación
ni `/api/token/refresh`: no existen en este kit. Si el usuario lo pide para un proyecto
concreto, se añade con ADR y se documenta en el contrato de esa instancia.

## Divergencia entre contratos

```bash
bash .claude/scripts/gate-contract.sh
```

Guarda el hash de cada `docs/contracts/<instancia>.md` en su `.lock` y falla **a propósito**
cuando uno cambia, hasta que hayas escrito el ADR y creado las dos tareas hermanas. Con varias
instancias, solo se pone en rojo la que cambió: las demás siguen en verde.

## Al añadir un endpoint

1. Escribe la entrada en `docs/contracts/<instancia>.md` **antes** de implementar: método, ruta,
   request, response de éxito, y los códigos de error posibles con su forma exacta.
2. Genera dos tareas hermanas que citen ese fragmento, indicando la instancia.
3. El test E2E del criterio de aceptación es lo que verifica que ambas coinciden.
