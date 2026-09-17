# Contrato API de `<instancia>`

> Fuente de verdad entre este backend y los frontends que lo consumen. Quien añade o cambia un
> endpoint actualiza este archivo **en la misma tarea**; el otro lado se escribe contra esto.

- **Frontends que lo consumen:** 
- **Última modificación:** 

## Convenciones (fijas en el kit)

- Todo bajo `/api`; documentación en `/api/docs`.
- Recursos en `application/ld+json` (`hydra_prefix: false`); escrituras `application/json`;
  PATCH `application/merge-patch+json`; endpoints custom en `application/json` plano.
- Campos `camelCase`. Fechas ISO 8601 UTC (`2026-07-13T15:00:00+00:00`). Relaciones como IRIs
  (`"category": "/api/categories/3"`).
- Colección: `{ "member": [...], "totalItems": 143, "view": { "next": "/api/x?page=2" } }`.
  Paginación `page` (1-based) e `itemsPerPage` (20 por defecto). Orden `?order[campo]=asc|desc`.
  Filtros declarados por recurso.
- Errores RFC 7807: `{ "status": 422, "detail": "...", "violations": [ { "propertyPath": "name", "message": "..." } ] }`.
  `400` malformado · `401` sin token o caducado · `403` sin permiso · `404` · `409` conflicto de
  negocio · `422` validación siempre con `violations[]` · `500` sin detalle interno.
- Auth: `POST /api/login_check` `{ "username", "password" }` → `200 { "token" }`, `401` si falla.
  `GET /api/me` → `{ "id", "username", "roles" }`. Cabecera `Authorization: Bearer <token>`, TTL 3600 s.
  **Sin refresh token**: al caducar, `401` → el frontend limpia la sesión y va a `/login?redirect=<ruta>`.
  Roles: `ROLE_USER`, `ROLE_ADMIN`.

## Recursos

### <Recurso>  —  `/api/<recursos>`

| Operación | Seguridad | Grupos |
|---|---|---|
| GET colección | `ROLE_USER` | `x:read` |
| GET item | `ROLE_USER` | `x:read`, `x:item:read` |
| POST | `ROLE_ADMIN` | `x:write` |
| PATCH | `is_granted('EDIT', object)` | `x:write` |
| DELETE | `ROLE_ADMIN` | — |

**Filtros:** `name` (partial), `status` (exact) · **Orden:** `name`, `createdAt`

| Campo | Tipo | Grupos | Validación |
|---|---|---|---|
| `id` | int | `x:read` | — |
| `name` | string | `x:read`, `x:write` | NotBlank, Length(2,120) |
| `createdAt` | datetime UTC | `x:read` | — |

## Endpoints custom

| Método y ruta | Seguridad | Request | 200 | Errores |
|---|---|---|---|---|
| `GET /api/me` | autenticado | — | `{ id, username, roles }` | `401` |
