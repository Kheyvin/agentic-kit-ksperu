---
name: backend
description: Estándar del backend Symfony 8 + API Platform 4 + JWT del kit — capas, entidades y migraciones sobre SQLite, recursos con operaciones explícitas, Voters, validación, grupos de serialización, errores RFC 7807 y comandos. Úsalo al escribir o revisar PHP de cualquier instancia backend.
---

# Backend — Symfony 8 + API Platform 4

Código y nombres en inglés; comentarios en español. `declare(strict_types=1);` en todo archivo.
Atributos PHP, nunca YAML de mapeo. SQLite en desarrollo.

Los ejemplos completos (security.yaml, api_platform.yaml, CORS, TimestampableTrait, recurso con
filtros, Voter, Processor, endpoint custom, fixtures, comando de importación) están en
[reference/patrones.md](reference/patrones.md). **Consúltalo por sección cuando necesites un
patrón; no lo leas entero.** Después del bootstrap, la base ya existe en la instancia:
`grep` antes de crear algo que quizá ya está.

## Capas (una sola dirección)

```
Operación API Platform | Controller  →  Service (reglas, transacciones)  →  Repository (consultas)  →  Entity
```

- Consultas **solo** en `src/Repository/`, con métodos nombrados por intención
  (`findActiveByOwner`). Cero QueryBuilder en services o controllers. Parámetros siempre bindeados.
- Lógica de negocio en `src/Service/`: clases `final readonly`, inyección por constructor.
  Transacción explícita (`wrapInTransaction`) cuando una operación toca varias entidades.
- Controllers solo para lo que no es un recurso (login, informes, acciones): single-action
  `__invoke`, delgados, sin tocar repositorios ni el EntityManager.
- Permiso sobre un objeto concreto → **Voter** (`is_granted('EDIT', object)`), nunca un `if`.

## Entidades y migraciones

1. Escribe o edita la entidad en `src/Entity/` con atributos (`#[ORM\Entity]`, `#[ORM\Column]`,
   `#[ORM\Index]`, `#[ORM\UniqueConstraint]`). `use TimestampableTrait` +
   `#[ORM\HasLifecycleCallbacks]` en toda entidad persistente. Fechas `\DateTimeImmutable` en UTC.
   No marques las entidades `final`. (`make:entity` también vale, pero es interactivo: respuestas
   por stdin y fácil de desalinear; escribir la clase es más fiable.)
2. `php bin/console make:migration`. **Nunca escribas ni edites una migración** (el hook lo
   bloquea): si sale mal, corrige la entidad y genera otra.
3. **Lee el SQL generado.** En SQLite casi todo `ALTER` se emula con `CREATE TABLE __temp__x` +
   `INSERT … SELECT` + `DROP TABLE` + `RENAME`; ese `DROP` es normal. Lo que hay que cazar: un
   `INSERT … SELECT` al que le falte una columna (pierde datos) o un `NOT NULL` nuevo sobre una
   tabla con filas (hazlo en tres migraciones: nullable → backfill → not null).
4. `php bin/console doctrine:migrations:migrate --no-interaction` y `doctrine:schema:validate`.

Índice en todo campo con filtro u orden en la API. Unicidad en BD **y** `#[UniqueEntity]`.
`cascade`/`orphanRemoval` solo con composición real. `fetch: 'EAGER'` prohibido: el N+1 se
resuelve con `addSelect` en el repositorio. El `schema:update` directo está bloqueado por hook,
sin excepción: siempre `make:migration`.

## Recursos API Platform

- `#[ApiResource]` **siempre con `operations:` explícitas y `security:` en cada una.**
  Sin `security` = pública.
- Grupos: `x:read` (colección e item), `x:item:read` (campos pesados solo en el detalle),
  `x:write`. **Ningún campo sale sin grupo.** `password`, hashes, tokens y campos internos jamás
  en un grupo de lectura.
- Filtros declarados uno a uno (`SearchFilter`, `OrderFilter`, `DateFilter`, `BooleanFilter`);
  nunca todos los campos.
- Lógica al leer o escribir → State Provider/Processor en `src/State/`, que delega en un Service
  (hashear `plainPassword`, asignar `owner = usuario actual` en POST).
- Payload distinto de la entidad → DTO `Input` en `src/Dto/`; respuesta calculada → DTO `Output`.
- Constraints en todo campo de escritura. La validación responde **`422` con
  `violations[{propertyPath, message}]`**: el frontend mapea por `propertyPath` y romper ese shape
  rompe todos los formularios. `409` para conflictos de negocio con excepción de dominio propia,
  nunca `\Exception` genérica. `500` sin detalle interno.
- Colecciones: `hydra_prefix: false`, 20 por página (mismo valor que `app.config.js` del
  frontend). Las relaciones se escriben como IRIs.

## Autenticación

Login por **`username`** (`POST /api/login_check` → `{token}`), `GET /api/me` →
`{id, username, roles}`, TTL 3600 s. **Sin refresh token**: no lo implementes aunque parezca
faltar. `access_control` cierra `^/api` con `IS_AUTHENTICATED_FULLY`; `/api/login` y `/api/docs`
públicos. CORS con los orígenes de los frontends; nunca `*`.

## Datos, importaciones y procesos pesados

- Fixtures: `admin`/`pass_1234` (`ROLE_ADMIN`), `user`/`pass_1234` (`ROLE_USER`) y volumen
  suficiente en lo que se lista (≥ 30 filas) para que paginación y filtros se prueben de verdad.
- Importaciones y procesos largos → comando de consola (`make:command`), idempotente (clave
  natural + upsert), validación del archivo entero antes de tocar la BD, lotes con
  `flush()` + `clear()`, transacción por lote e informe de filas leídas, insertadas,
  actualizadas y rechazadas.
- Mailer, Messenger y Mercure **solo si el usuario los pidió**.

## Comandos

```bash
php bin/console make:migration && php bin/console doctrine:migrations:migrate --no-interaction
php bin/console doctrine:schema:validate
php bin/console doctrine:fixtures:load --no-interaction
php bin/console cache:clear
php bin/console debug:router | grep api            # qué rutas existen de verdad
symfony server:start --no-tls -d                   # http://localhost:8000 (lee el puerto real que imprime)
curl -s -X POST -H "Content-Type: application/json" http://localhost:8000/api/login_check -d '{"username":"admin","password":"pass_1234"}'
```

## Antes de cerrar

`bash .claude/scripts/gate-backend.sh <instancia>` en verde. A mano: grupos sin fugas, `security:`
en cada operación, filtros con índice, `docs/contracts/<instancia>.md` actualizado si tocaste
endpoints, y una llamada real con `curl` (con token) al endpoint nuevo.
