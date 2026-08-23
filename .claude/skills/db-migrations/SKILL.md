---
name: db-migrations
description: Diseño de entidades Doctrine y revisión de migraciones — índices, relaciones, reversibilidad, bloqueos y cambios destructivos. Úsalo al crear o modificar entidades, generar migraciones o revisar cualquier archivo en migrations/.
---

# Modelo de datos y migraciones

## Diseño de entidad

- Se genera con `make:entity`. Nunca a mano, nunca SQL directo.
- `TimestampableTrait` (createdAt/updatedAt inmutables) en **toda** entidad persistente.
- Fechas `\DateTimeImmutable` con `Types::DATETIME_IMMUTABLE`, siempre UTC.
- `#[ORM\Index]` en todo campo por el que se filtre u ordene desde la API. Un filtro declarado
  sin índice es una bomba de rendimiento con retardo.
- `#[ORM\UniqueConstraint]` en BD **más** `#[UniqueEntity]` para el mensaje 422. Solo el
  segundo es una condición de carrera esperando a ocurrir.
- Nullable explícito y justificado: si un campo no puede faltar, `nullable: false` desde el día
  uno. Volverlo obligatorio después exige backfill.
- `#[ORM\Version]` en entidades editables concurrentemente (lock optimista).
- Soft delete solo si el dominio lo pide, con filtrado en el repositorio y documentado.

## Relaciones

- Dueño de la relación explícito; `inversedBy`/`mappedBy` correctos.
- `cascade` y `orphanRemoval` **solo** con composición real (la hija no existe sin la madre).
  Un `cascade: ['remove']` mal puesto borra medio esquema sin avisar.
- `fetch: 'EAGER'` está prohibido: resuelve el N+1 con `addSelect` en el repositorio.

## Revisión de la migración generada

Antes de commitear, **lee el SQL**. Verifica:

- [ ] `down()` implementado y realmente reversible.
- [ ] Sin `DROP COLUMN`/`DROP TABLE` inesperado (señal típica: entidad renombrada sin cuidado).
- [ ] Columna nueva `NOT NULL` sobre tabla con datos → falla al aplicar. Patrón correcto:
      nullable → backfill → `NOT NULL`, en **tres** migraciones.
- [ ] `ALTER TABLE` sobre tabla grande: en MySQL/MariaDB bloquea. Anótalo en la tarea.
- [ ] Índices creados junto a la columna, no "después".
- [ ] Una migración por cambio lógico. No acumular semanas de diff en un archivo.
- [ ] Nunca editar una migración ya aplicada en otro entorno: se crea una nueva.

## Flujo

```bash
php bin/console make:entity Product
php bin/console make:migration
# ← LEER migrations/VersionXXXX.php AQUÍ
php bin/console doctrine:migrations:migrate
php bin/console doctrine:schema:validate --skip-sync
```

`doctrine:schema:update` está bloqueado por hook y no hay excepción.

## Datos de prueba

Fixtures con usuario admin y usuario normal de credenciales conocidas —las consume el smoke de
Playwright— y volumen realista en las entidades que se listan: 100+ filas para que la paginación
y los índices se prueben de verdad.
