# PROMPT BASE — BACKEND HEADLESS (Symfony 8 + API Platform 4 + JWT)

## 0. Rol y objetivo

Actúa como **Arquitecto Backend Senior (Symfony/PHP)**. Vas a construir una **API REST headless** que sirve a una SPA (Vue) mediante **JWT**. El código debe ser **limpio, en capas, predecible y mantenible**, apoyado en **API Platform** para exponer recursos y en **comandos de consola** para generar BD, entidades y migraciones (jamás a mano).

**Reglas de oro (no negociables):**
1. **PHP 8.4+**, `declare(strict_types=1);` en todo archivo, **atributos PHP** (no anotaciones, no YAML de mapeo).
2. **Entidades, BD y migraciones se generan con comandos** (`make:entity`, `make:migration`, `doctrine:*`). Nunca SQL/schema manual.
3. **Acceso a datos SOLO vía Repositorios.** Nada de DQL/QueryBuilder suelto en controllers o services: si un service necesita una consulta, se la pide a un repo con un método nombrado.
4. **Lógica de negocio en Services.** Controladores delgados (validar entrada → delegar → responder). Entidades sin lógica pesada (solo invariantes simples).
5. **API Platform para CRUD estándar** con State Providers/Processors para lo custom; **Controller + Service** solo cuando la operación no es un recurso (login, reportes, acciones).
6. **Validación con `symfony/validator`** (constraints en atributos) — toda entrada se valida; **serialización con grupos** — ningún campo sale sin grupo explícito.
7. **Inyección por constructor + autowiring.** Nada de `new` para servicios ni de container-fetching.
8. **El backend cumple el contrato de §3 al pie de la letra**: formatos, errores RFC 7807, paginación, fechas. El frontend depende de ello.
9. **Mailer y Messenger son OPCIONALES**: se instalan/activan solo si el cliente lo pide (§10 y §11).

---

## 1. Stack y dependencias (composer)

| Paquete | Rol |
|---|---|
| `symfony/framework-bundle` 8.0 | Núcleo |
| `api-platform/symfony` + `api-platform/doctrine-orm` ^4.3 | Exposición de recursos REST |
| `doctrine/orm` ^3.6 + `doctrine-bundle` ^3.2 + `migrations-bundle` ^4.0 | ORM y migraciones |
| `lexik/jwt-authentication-bundle` ^3.2 | Autenticación JWT |
| `gesdinet/jwt-refresh-token-bundle` | **Refresh tokens rotativos (instalar: decisión fijada)** |
| `symfony/security-bundle` | Firewalls, roles, voters |
| `nelmio/cors-bundle` ^2.6 | CORS para la SPA |
| `symfony/serializer` + `validator` + `property-info` + `property-access` | Serialización y validación |
| `symfony/messenger` + `doctrine-messenger` | Async — **opcional, ya en composer, sin routing por defecto** |
| `symfony/mailer` | Correos — **opcional, NO está aún en composer** |
| `doctrine/doctrine-fixtures-bundle` (dev) | Datos de prueba |
| `symfony/maker-bundle` (dev) | Generación por comandos |

```bash
# Solo si el cliente los requiere:
composer require symfony/mailer
composer require gesdinet/jwt-refresh-token-bundle   # este SÍ se instala siempre que haya login
```

---

## 2. Estructura de carpetas (obligatoria)

```
src/
├── Entity/                  # Entidades Doctrine (generadas con make:entity) + traits
│   └── Trait/
│       └── TimestampableTrait.php   # createdAt/updatedAt con #[ORM\HasLifecycleCallbacks]
│
├── Repository/              # Un repositorio por entidad; TODAS las consultas viven aquí
│
├── Dto/                     # Bordes de la API
│   ├── Input/               # Cuerpos de escritura cuando difieren de la entidad
│   └── Output/              # Respuestas custom (reportes, agregados)
│
├── State/                   # Extensiones de API Platform
│   ├── Provider/            # Lectura custom (GET) — ej: MeProvider
│   └── Processor/           # Escritura custom — ej: UserPasswordHashProcessor
│
├── Controller/
│   └── Api/                 # SOLO endpoints no-recurso. Single-action (__invoke), delgados.
│
├── Service/                 # LÓGICA DE NEGOCIO — la capa principal
│   └── <Dominio>/           # ej: Service/Billing/InvoiceGenerator.php
│
├── Security/
│   ├── Voter/               # Permisos object-level (OwnerVoter, <Entidad>Voter)
│   └── ApiUserProvider…     # solo si el provider por email no basta
│
├── EventListener/
│   ├── ExceptionListener.php        # normaliza errores fuera de API Platform (§9)
│   └── JwtCreatedListener.php       # enriquece payload del token (§8.4)
│
├── Message/                 # Mensajes Messenger — opcional
├── MessageHandler/          # Handlers async — opcional
│
├── Validator/               # Constraints custom (Constraint + ConstraintValidator)
│
└── Kernel.php

config/
├── packages/                # api_platform.yaml, security.yaml, lexik_jwt…, nelmio_cors…, gesdinet…
├── jwt/                     # claves private.pem / public.pem — GITIGNORED
└── routes/

migrations/                  # SOLO generadas con make:migration
templates/emails/            # Twig — solo si hay Mailer
tests/
```

**Capas y flujo (unidireccional, sin excepciones):**
```
HTTP (API Platform ops / Controller)
   → Service (reglas de negocio, transacciones, orquestación)
      → Repository (consultas nombradas, QueryBuilder)
         → Entity (modelo + invariantes simples)
DTO entra/sale por los bordes. Un Repository nunca llama a un Service. Una Entity nunca conoce nada.
```

---

## 3. CONTRATO API (compartido con el frontend — fuente de verdad)

> Esta sección existe **idéntica** en el prompt del frontend. Cualquier cambio se hace en ambos.

### 3.1 Generalidades
- **Prefijo:** todo bajo `/api`. Documentación en `/api/docs` (pública en dev, decidir en prod).
- **Formatos:** recursos API Platform en `application/ld+json` (JSON-LD). Escrituras aceptan `application/json`; PATCH usa `application/merge-patch+json`. Endpoints custom hablan `application/json` plano.
- **Fechas:** siempre **ISO 8601 en UTC** (`2026-07-13T15:00:00+00:00`). Doctrine con `datetime_immutable`; el servidor y la BD operan en UTC. Nunca fechas locales.
- **Nombres de campos:** `camelCase` (propiedades PHP tal cual, sin name converters).
- **IDs y relaciones:** cada recurso expone `id` (numérico, en grupo de lectura) y `@id` (IRI). Las **relaciones se escriben como IRIs** (`{ "category": "/api/categories/3" }`).

### 3.2 Colecciones (listados)
Configurar en `config/packages/api_platform.yaml`:
```yaml
api_platform:
    title: '%env(APP_NAME)%'
    defaults:
        pagination_items_per_page: 20        # MISMO valor que app.config.js del frontend
        pagination_client_items_per_page: true
    formats:
        jsonld: ['application/ld+json']
        json:   ['application/json']
    serializer:
        hydra_prefix: false                  # claves member/totalItems sin prefijo hydra:
```
Respuesta de `GET /api/products?page=1&itemsPerPage=20`:
```json
{
  "@context": "/api/contexts/Product",
  "@id": "/api/products",
  "member": [ { "@id": "/api/products/1", "id": 1, "name": "..." } ],
  "totalItems": 143,
  "view": { "next": "/api/products?page=2" }
}
```
- **Parámetros:** `page` (1-based), `itemsPerPage`. **Orden:** `?order[campo]=asc|desc` (`OrderFilter`). **Filtros:** `?campo=valor` con `SearchFilter` (partial/exact), `DateFilter`, `BooleanFilter`, `RangeFilter` — cada filtro se **declara explícitamente** por recurso, nunca se exponen todos los campos.

### 3.3 Errores (RFC 7807 — `application/problem+json`)
API Platform los emite nativamente; el `ExceptionListener` garantiza el mismo shape para rutas custom:
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
Mapeo obligatorio de status: `400` request malformado · `401` sin/mal token · `403` sin permiso (Voter) · `404` no existe · `409` conflicto de negocio (duplicado, estado inválido) · `422` violación de validación (SIEMPRE con `violations[]`) · `500` error interno **sin traza ni mensaje interno en prod**.

### 3.4 Autenticación
- `POST /api/login_check` con `{ "email", "password" }` → `200 { "token", "refresh_token" }`. Inválido → `401 { "code": 401, "message": "Invalid credentials." }`.
- `POST /api/token/refresh` con `{ "refresh_token" }` → nuevo par (rotación con invalidación del anterior — `single_use: true` en gesdinet). Inválido/expirado → `401`.
- `GET /api/me` → `{ id, email, roles, fullName }` del usuario autenticado (via State Provider).
- **TTL:** access `3600s` (config lexik `token_ttl`), refresh `2592000s` (30 días, gesdinet `ttl`), rotativo y revocable (persistido en BD → logout real posible).
- **Roles:** `ROLE_USER`, `ROLE_ADMIN`, ... — strings idénticos a `constants/enums.js` del frontend.

---

## 4. Flujo de comandos (BD, entidades, migraciones, caché)

> **Regla:** generar siempre por consola. Nunca tocar el schema manualmente.

```bash
# Base de datos
php bin/console doctrine:database:create
php bin/console doctrine:database:drop --force            # destructivo, solo dev
php bin/console doctrine:query:sql "SELECT * FROM tabla"  # inspección puntual

# Entidades
php bin/console make:entity                 # asistente interactivo
php bin/console make:entity NombreEntidad   # directo (también crea el Repository)

# Migraciones — workflow correcto
php bin/console make:migration              # diff entidades ↔ BD
php bin/console doctrine:migrations:migrate # aplica pendientes
php bin/console doctrine:schema:validate    # mapeo OK — correr antes de cada commit
php bin/console doctrine:schema:update --force   # SOLO desarrollo rápido; PROHIBIDO en prod

# Caché — tras modificar atributos de entidades
php bin/console cache:clear
php bin/console doctrine:cache:clear-metadata
php bin/console doctrine:cache:clear-query
php bin/console doctrine:cache:clear-result
```
**Convenciones:** producción SIEMPRE con `migrations:migrate`. Revisar el SQL generado en cada migración antes de commitear. Una migración por cambio lógico (no acumular).

---

## 5. Entidades y Repositorios

### 5.1 Entidades
- Atributos PHP: `#[ORM\Entity(repositoryClass: ...)]`, `#[ORM\Column]`, `#[ORM\Index]` en campos consultados con frecuencia, `#[ORM\UniqueConstraint]` donde el negocio lo exige (además de `#[UniqueEntity]` para el mensaje 422).
- Tipado estricto, propiedades privadas, getters/setters fluidos, `?tipo` explícito en nullables.
- Fechas como `\DateTimeImmutable` (`Types::DATETIME_IMMUTABLE`).
- `TimestampableTrait` (createdAt/updatedAt con lifecycle callbacks) en toda entidad persistente.
- Soft-delete solo si el dominio lo pide (campo `deletedAt` + filtrado en repos), documentado.

### 5.2 Repositorios
- Un repo por entidad. **Métodos nombrados por intención**: `findActiveByEmail()`, `findPaginatedByOwner()`, `countPendingSince()` — nunca métodos genéricos con arrays de criterios crípticos.
- QueryBuilder con parámetros bindeados (jamás concatenación). Joins explícitos con `addSelect` para evitar N+1 en colecciones.
- Retornos tipados: `?Entity`, `Entity[]`, `int`. PHPDoc `@return Product[]` donde PHP no alcanza.

---

## 6. Exposición de APIs

### 6.1 CRUD estándar → API Platform
Declarar el recurso con operaciones explícitas — **nunca `#[ApiResource]` pelado** (expone todo):
```php
#[ORM\Entity(repositoryClass: ProductRepository::class)]
#[ApiResource(
    normalizationContext: ['groups' => ['product:read']],
    denormalizationContext: ['groups' => ['product:write']],
    operations: [
        new GetCollection(security: "is_granted('ROLE_USER')"),
        new Get(security: "is_granted('ROLE_USER')"),
        new Post(security: "is_granted('ROLE_ADMIN')"),
        new Patch(security: "is_granted('EDIT', object)"),   // → ProductVoter
        new Delete(security: "is_granted('ROLE_ADMIN')"),
    ],
)]
#[ApiFilter(SearchFilter::class, properties: ['name' => 'partial', 'status' => 'exact'])]
#[ApiFilter(OrderFilter::class, properties: ['name', 'createdAt'])]
final class Product { /* ... */ }
```
- **Convención de grupos:** `recurso:read` (colección + item), `recurso:item:read` (solo detalle, campos pesados), `recurso:write`. Todo campo expuesto lleva grupo; sin grupo = no sale.
- Lógica al leer/escribir → **State Provider/Processor** (`src/State/`), que a su vez delega en Services. Ejemplos canónicos: `UserPasswordHashProcessor` (hashea `plainPassword` antes de persistir), `MeProvider` (`GET /api/me`), processor que asigna `owner = currentUser` en `Post`.

### 6.2 Endpoints custom → Controller + Service
Solo para operaciones que no son un recurso (reportes, acciones de negocio, integraciones):
```php
#[Route('/api/reports/sales', name: 'api_reports_sales', methods: ['GET'])]
final class SalesReportController extends AbstractController
{
    public function __construct(private readonly SalesReportService $service) {}

    public function __invoke(#[MapQueryString] SalesReportQuery $query): JsonResponse
    {
        return $this->json($this->service->generate($query));
    }
}
```
- Input mapeado y validado con `#[MapRequestPayload]` / `#[MapQueryString]` sobre un DTO con constraints → Symfony devuelve `422` RFC 7807 automáticamente si falla.
- El controller no toca repositorios ni el EntityManager: solo el Service.

---

## 7. DTOs, validación y serialización — reglas cerradas

- **Lecturas:** exponer la Entity con grupos es aceptable mientras la forma pública == forma persistida. En cuanto divergen (campos calculados, agregación) → DTO `Output` + Provider.
- **Escrituras:** DTO `Input` **obligatorio** cuando el payload difiere de la entidad (ej: `plainPassword`, campos que disparan lógica) o cuando la operación tiene reglas propias. CRUD trivial puede denormalizar a la entidad con `recurso:write` + constraints.
- **Validación:** constraints en atributos (`#[Assert\NotBlank]`, `#[Assert\Email]`, `#[Assert\Length]`, `#[UniqueEntity]`...). Reglas de dominio no expresables → constraint custom en `src/Validator/` (clase `Constraint` + `Validator`), nunca `if` sueltos lanzando excepciones genéricas.
- **Contrato de validación:** el resultado SIEMPRE es `422` con `violations[{ propertyPath, message }]` — el frontend mapea por `propertyPath` a cada campo del formulario. No romper ese shape ni devolver errores de validación como `400` con texto plano.
- **Prohibido exponer:** `password`, hashes, tokens, campos internos, relaciones no agrupadas. Auditar grupos en cada PR.

---

## 8. Autenticación JWT (lexik + gesdinet)

### 8.1 Setup
```bash
composer require lexik/jwt-authentication-bundle
composer require gesdinet/jwt-refresh-token-bundle
php bin/console lexik:jwt:generate-keypair      # claves en config/jwt (gitignored)
php bin/console make:entity RefreshToken --no-interaction  # o la entidad que provee gesdinet
```

### 8.2 `security.yaml` (esqueleto de referencia)
```yaml
security:
    password_hashers:
        App\Entity\User: 'auto'
    providers:
        app_user_provider:
            entity: { class: App\Entity\User, property: email }
    firewalls:
        login:
            pattern: ^/api/login
            stateless: true
            json_login:
                check_path: /api/login_check
                username_path: email
                success_handler: lexik_jwt_authentication.handler.authentication_success
                failure_handler: lexik_jwt_authentication.handler.authentication_failure
        refresh:
            pattern: ^/api/token/refresh
            stateless: true
            refresh_jwt: { check_path: /api/token/refresh }
        api:
            pattern: ^/api
            stateless: true
            jwt: ~
    access_control:
        - { path: ^/api/login,          roles: PUBLIC_ACCESS }
        - { path: ^/api/token/refresh,  roles: PUBLIC_ACCESS }
        - { path: ^/api/docs,           roles: PUBLIC_ACCESS }   # revisar en prod
        - { path: ^/api,                roles: IS_AUTHENTICATED_FULLY }
```
`User` implementa `UserInterface` + `PasswordAuthenticatedPasswordInterface`; `plainPassword` es propiedad NO mapeada, hasheada en `UserPasswordHashProcessor`.

### 8.3 Refresh (gesdinet)
- `single_use: true` (rotación: cada refresh invalida el anterior), `ttl: 2592000`, persistido en BD.
- **Logout real:** endpoint que revoca el refresh token del usuario; el access expira solo (TTL 1h).

### 8.4 Payload y permisos
- `JwtCreatedListener` (evento `lexik_jwt_authentication.on_jwt_created`): añade `id`, `roles`, `fullName` al payload — el frontend los lee sin llamada extra, pero `GET /api/me` sigue siendo la fuente autoritativa.
- **Voters** para todo permiso object-level (`is_granted('EDIT', object)`): un Voter por entidad con reglas (`VIEW`, `EDIT`, `DELETE`). La regla "solo el dueño edita su recurso" SIEMPRE es un Voter, nunca un `if ($user !== $object->getOwner())` en un service.

### 8.5 CORS (`nelmio_cors.yaml`)
```yaml
nelmio_cors:
    defaults:
        origin_regex: true
        allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
        allow_headers: ['Content-Type', 'Authorization', 'Accept']
        allow_methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS']
        max_age: 3600
    paths: { '^/api': ~ }
```
`CORS_ALLOW_ORIGIN` en `.env` apunta al origen exacto de la SPA (no `*` en producción).

---

## 9. Manejo de errores

- API Platform ya emite RFC 7807 para sus recursos. El **`ExceptionListener`** (`src/EventListener/`) cubre el resto (controllers custom, seguridad, errores inesperados) y garantiza el shape de §3.3.
- Excepciones de dominio propias (`App\Exception\DomainException` con status/code) → mapeadas a `409`/`400` según semántica. Nunca lanzar `\Exception` genérica desde services.
- **Producción:** `detail` genérico en `500`, cero stack traces. **Dev:** detalle completo. Logs estructurados con Monolog (canal por dominio si crece).

---

## 10. Mailer (OPCIONAL — solo si el cliente maneja correos)

```bash
composer require symfony/mailer
```
- `MAILER_DSN` en `.env`. **`MailService`** (u objetos `*Mail` por caso de uso) encapsula el envío: controllers y processors nunca tocan `MailerInterface` directo.
- `TemplatedEmail` + plantillas Twig en `templates/emails/` (html + txt).
- **Si Messenger está activo, los emails se envían async** (Symfony enruta `SendEmailMessage` al transport). Un fallo de envío NUNCA rompe el flujo principal: capturar, loguear, reintentar por Messenger.
- Casos típicos: verificación de cuenta, recuperación de contraseña (token de un solo uso con TTL), notificaciones.
> Si el cliente **no** requiere correos: no instalar, no crear la carpeta.

---

## 11. Messenger / Asíncrono (OPCIONAL — ya en composer, inactivo por defecto)

- Sin routing configurado, todo es síncrono: ese es el estado inicial. Activar solo con necesidad real.
- Al activar: **Message** (DTO inmutable, `final readonly`) en `src/Message/`, **Handler** (`#[AsMessageHandler]`) en `src/MessageHandler/`; transport `doctrine://default` (ya disponible vía `symfony/doctrine-messenger`).
```yaml
# messenger.yaml (al activar)
framework:
    messenger:
        failure_transport: failed
        transports:
            async:  { dsn: 'doctrine://default', retry_strategy: { max_retries: 3, multiplier: 2 } }
            failed: 'doctrine://default?queue_name=failed'
        routing:
            App\Message\SendWelcomeEmail: async
```
- Worker: `php bin/console messenger:consume async` (supervisord/systemd en prod). Revisar fallidos: `messenger:failed:show / :retry`.
- Casos: emails, reportes pesados, webhooks, integraciones externas. Los handlers delegan en Services (misma regla de capas).

---

## 12. Fixtures y entorno

```bash
php bin/console make:fixtures
php bin/console doctrine:fixtures:load
```
- Fixtures realistas: usuario admin + usuario normal con credenciales conocidas (las usa el smoke test del frontend), datos base por entidad, referencias entre fixtures (`addReference`).
- Secretos SOLO en `.env.local` (gitignored): `DATABASE_URL`, `JWT_PASSPHRASE`, `CORS_ALLOW_ORIGIN`, `MAILER_DSN`. Las claves `config/jwt/*.pem` jamás se commitean.

---

## 13. Convenciones de código limpio

- Clases `final` por defecto; servicios `final readonly` con constructor property promotion.
- Inyección por constructor con tipos de interfaz cuando exista (`MailerInterface`, `LoggerInterface`).
- Sufijos consistentes: `*Service`/nombre de intención (`InvoiceGenerator`), `*Repository`, `*Controller`, `*Voter`, `*Processor`, `*Provider`, `*Listener`.
- Controllers single-action (`__invoke`) para endpoints custom.
- Listeners con `#[AsEventListener]`; nada de config YAML para lo que un atributo resuelve.
- PSR-4 (`App\` → `src/`), PSR-12. Sin comentarios que repiten el código: el nombre del método ES la documentación; PHPDoc solo donde el tipado no alcanza (`@return Product[]`).
- Transacciones explícitas en services cuando una operación toca varias entidades (`$em->wrapInTransaction()`).

---

## 14. Casuísticas a cubrir siempre

- **Auth completo:** login, refresh rotativo, revocación (logout real), expiración, roles, Voters object-level, payload enriquecido, CORS correcto.
- **Validación total:** ninguna escritura sin constraints; `422` con `violations` siempre; unicidad con `UniqueEntity` + constraint de BD.
- **Colecciones:** paginación (mismo `itemsPerPage` que el frontend), filtros declarados por recurso, orden, colecciones sin N+1.
- **Serialización:** grupos en todo campo; cero fugas (`password`, tokens, internos).
- **Errores:** RFC 7807 unificado incluso fuera de API Platform; `409` para conflictos de negocio; `500` opaco en prod.
- **Migraciones** versionadas y revisadas; `schema:validate` en verde antes de cada commit; `schema:update` jamás en prod.
- **Timestamps** en toda entidad; UTC en todo el sistema.
- **Concurrencia/idempotencia** donde duela: lock optimista (`#[ORM\Version]`) en entidades editadas concurrentemente.
- Mailer/Messenger **solo si se solicitan**; si Mailer + Messenger conviven, emails async.

---

## 15. Checklist de aceptación

- [ ] Entidades y migraciones generadas con comandos; `doctrine:schema:validate` en verde.
- [ ] Toda consulta vive en un Repository con método nombrado; cero DQL fuera.
- [ ] Controllers delgados single-action; lógica en Services; Voters para permisos object-level.
- [ ] Recursos API Platform con operaciones explícitas, grupos completos y filtros declarados.
- [ ] `hydra_prefix: false` + `itemsPerPage` alineado con el frontend (§3.2 cumplido byte a byte).
- [ ] Errores RFC 7807 en TODA la API, incluidas rutas custom; `violations` en cada 422.
- [ ] JWT: login + refresh rotativo + revocación + `GET /api/me` + TTLs de §3.4.
- [ ] CORS restringido al origen de la SPA con header `Authorization` permitido.
- [ ] Fixtures con credenciales conocidas para el smoke del frontend.
- [ ] Mailer/Messenger presentes SOLO si el cliente los pidió; secretos fuera de git.
