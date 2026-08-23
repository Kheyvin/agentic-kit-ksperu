# Contrato API — fuente de verdad

> Este archivo lo consumen backend y frontend por igual. **Cambiarlo exige un ADR y dos tareas
> hermanas** (backend + frontend) en el mismo lote. Un cambio unilateral es un incidente.

- **Versión:** 1
- **Última modificación:** 
- **ADR relacionado:** 

## Generalidades

- Prefijo `/api`. Documentación en `/api/docs`.
- Recursos en `application/ld+json`; escrituras `application/json`;
  PATCH `application/merge-patch+json`. Endpoints custom en `application/json` plano.
- Fechas ISO 8601 **UTC**: `2026-07-13T15:00:00+00:00`.
- Campos en `camelCase`. Relaciones como IRIs: `{ "category": "/api/categories/3" }`.
- Paginación: `page` (1-based), `itemsPerPage` (**20**, mismo valor en backend y `app.config.js`).
- Orden: `?order[campo]=asc|desc`. Filtros declarados por recurso.

## Colección — forma de respuesta

```json
{ "member": [ { "@id": "/api/x/1", "id": 1 } ], "totalItems": 143,
  "view": { "next": "/api/x?page=2" } }
```

## Errores — RFC 7807

```json
{ "status": 422, "title": "An error occurred", "detail": "...",
  "violations": [ { "propertyPath": "name", "message": "..." } ] }
```

`400` malformado · `401` sin/mal token · `403` sin permiso · `404` no existe ·
`409` conflicto de negocio · `422` validación siempre con `violations[]` · `500` opaco en prod.

## Autenticación

| Endpoint | Request | 200 | Errores |
|---|---|---|---|
| `POST /api/login_check` | `{email, password}` | `{token, refresh_token}` | `401` |
| `POST /api/token/refresh` | `{refresh_token}` | `{token, refresh_token}` | `401` |
| `GET /api/me` | — | `{id, email, roles, fullName}` | `401` |

TTL access `3600s`; refresh `2592000s`, rotativo y revocable.
Roles: `ROLE_USER`, `ROLE_ADMIN` — idénticos en `constants/enums.js`.

---

## Recursos

### <Recurso>

| Operación | Ruta | Seguridad | Grupos |
|---|---|---|---|
| GET colección | `/api/x` | `ROLE_USER` | `x:read` |
| GET item | `/api/x/{id}` | `ROLE_USER` | `x:read`, `x:item:read` |
| POST | `/api/x` | `ROLE_ADMIN` | `x:write` |
| PATCH | `/api/x/{id}` | `is_granted('EDIT', object)` | `x:write` |
| DELETE | `/api/x/{id}` | `ROLE_ADMIN` | — |

**Filtros declarados:** `name` (partial), `status` (exact) · **Orden:** `name`, `createdAt`

**Campos**

| Campo | Tipo | Grupos | Validación |
|---|---|---|---|
| `id` | int | `x:read` | — |
| `name` | string | `x:read`, `x:write` | NotBlank, Length(2,120) |
| `createdAt` | ISO 8601 UTC | `x:read` | — |
