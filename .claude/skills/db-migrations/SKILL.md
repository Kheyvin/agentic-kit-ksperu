---
name: db-migrations
description: Diseño de entidades Doctrine con make:entity y revisión de migraciones sobre SQLite — índices, relaciones, reversibilidad y cambios destructivos. Úsalo al crear o modificar entidades, generar migraciones o revisar cualquier archivo en migrations/.
---

# Modelo de datos y migraciones

El motor de desarrollo es **SQLite** (`DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"`).
No hay producción en este kit: todo lo que se diseña aquí corre sobre SQLite salvo que el
usuario indique lo contrario, y en ese caso hay que avisarle de que cambie `.env`.

## Las entidades se generan, nunca se escriben

`make:entity` es **interactivo**: lanzado sin más desde un agente, se queda esperando en stdin
hasta agotar el tiempo. Se le pasan las respuestas por tubería.

```bash
php bin/console make:entity
```

Secuencia de respuestas, en orden: nombre de la clase, y luego por cada campo
`nombre → tipo → [longitud, solo si es string] → nullable`. Una línea vacía cierra.

```bash
# Product { name: string(255) NOT NULL, price: integer NOT NULL }
printf 'Product\nname\nstring\n255\nno\nprice\ninteger\nno\n\n' | php bin/console make:entity
```

Cuidado con la longitud: **`string` pregunta longitud y los demás tipos no**. Si metes un `255`
de más, la respuesta se desalinea y acabas con un campo llamado `255`. Cuando la entidad sea
larga o tenga relaciones, hazla en varias pasadas cortas y revisa el archivo entre una y otra:
`make:entity` sobre una clase existente añade campos sin borrar los que ya hay.

El hook `guard.sh` **bloquea crear un archivo nuevo en `src/Entity/` a mano**. Editar una
entidad ya generada sí se permite: es donde se añaden los atributos de API Platform, los grupos
de serialización y los índices.

## Diseño de entidad

- `TimestampableTrait` (createdAt/updatedAt inmutables) en **toda** entidad persistente.
- Fechas `\DateTimeImmutable` con `Types::DATETIME_IMMUTABLE`, siempre UTC.
- `#[ORM\Index]` en todo campo por el que se filtre u ordene desde la API. Un filtro declarado
  sin índice es una bomba de rendimiento con retardo.
- `#[ORM\UniqueConstraint]` en BD **más** `#[UniqueEntity]` para el mensaje 422. Solo el
  segundo es una condición de carrera esperando a ocurrir.
- Nullable explícito y justificado: si un campo no puede faltar, `nullable: false` desde el día
  uno. Volverlo obligatorio después exige backfill.
- Soft delete solo si el dominio lo pide, con filtrado en el repositorio y documentado.

## Relaciones

- Dueño de la relación explícito; `inversedBy`/`mappedBy` correctos.
- `cascade` y `orphanRemoval` **solo** con composición real (la hija no existe sin la madre).
  Un `cascade: ['remove']` mal puesto borra medio esquema sin avisar.
- `fetch: 'EAGER'` está prohibido: resuelve el N+1 con `addSelect` en el repositorio.

## Lo que SQLite hace distinto — y hay que tener en cuenta

SQLite no tiene un `ALTER TABLE` completo. Doctrine lo emula: **crea una tabla nueva, copia los
datos, borra la vieja y renombra**. Consecuencias reales al leer una migración:

- Una migración que solo añade una columna genera `CREATE TABLE __temp__x`, `INSERT INTO … SELECT`,
  `DROP TABLE x`, `ALTER TABLE __temp__x RENAME TO x`. **Ese `DROP TABLE` es normal**, no es el
  accidente que hay que buscar. Lo que sí es un accidente es un `DROP TABLE` sin su `INSERT …
  SELECT` previo, o un `SELECT` que no lista todas las columnas que existían.
- En ese `INSERT … SELECT` se pierde cualquier columna que Doctrine no crea que existe. Si
  editaste el esquema por fuera del ORM, aquí se borran datos sin avisar.
- Los índices se recrean junto con la tabla. Si un índice desaparece del `CREATE TABLE` nuevo,
  desapareció de verdad.
- Los tipos son laxos: SQLite acepta texto en una columna `integer`. Un error de tipo que aquí
  pasa desapercibido reventaría en otro motor. `doctrine:schema:validate` es lo que lo caza.
- Escritura de un solo escritor: dos procesos escribiendo a la vez dan `database is locked`.
  Si un test E2E falla con eso, el problema es de concurrencia del test, no del código.

Columna nueva `NOT NULL` sobre una tabla con datos sigue fallando igual que en cualquier motor.
Patrón correcto: **nullable → backfill → `NOT NULL`**, en tres migraciones.

## Revisión de la migración generada

Antes de aplicarla, **lee el SQL**. El hook bloquea escribir o editar archivos de `migrations/`
a mano: si está mal, se corrige la entidad y se genera otra.

- [ ] `down()` implementado y realmente reversible.
- [ ] En el ciclo `__temp__`, el `INSERT … SELECT` lista **todas** las columnas que sobreviven.
- [ ] Ningún `DROP COLUMN`/`DROP TABLE` que no forme parte de ese ciclo.
- [ ] Índices presentes en el `CREATE TABLE` resultante.
- [ ] Una migración por cambio lógico. No acumular semanas de diff en un archivo.
- [ ] Nunca editar una migración ya aplicada: se crea una nueva.

## Flujo

```bash
printf 'Product\nname\nstring\n255\nno\n\n' | php bin/console make:entity
php bin/console make:migration
# ← LEER migrations/VersionXXXX.php AQUÍ
php bin/console doctrine:migrations:migrate --no-interaction
php bin/console doctrine:schema:validate --skip-sync
```

`doctrine:schema:update` está bloqueado por hook y no hay excepción.

## Datos de prueba

Fixtures con el usuario `admin` / `pass_1234` que consumen los tests E2E, y un usuario sin
privilegios para probar los `403`. En las entidades que se listan en pantalla, volumen
suficiente para que la paginación y los filtros se prueben de verdad: con cinco filas, un
listado roto parece correcto.
