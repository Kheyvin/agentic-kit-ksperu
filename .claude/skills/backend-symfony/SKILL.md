---
name: backend-symfony
description: Estándar de backend headless Symfony 8 + API Platform 4 + JWT — capas, entidades, repositorios, services, State Providers/Processors, Voters, validación, serialización por grupos y manejo de errores. Úsalo al escribir o revisar cualquier PHP del proyecto API.
---

# Backend headless — Symfony 8 + API Platform 4

El estándar completo, largo y normativo está en `reference/backend-standard.md`.
**Léelo entero antes de la primera tarea de backend de una sesión.** Este archivo es el
resumen operativo para no reabrirlo en cada cambio pequeño.

La base de datos de desarrollo es **SQLite**. No hay producción: de subir el proyecto se
encarga el usuario.

## Reglas de oro

1. PHP 8.4+, `declare(strict_types=1);` en todo archivo, atributos PHP (nunca YAML de mapeo).
2. Entidades, BD y migraciones **se generan con comandos**. Jamás SQL ni schema a mano.
   `make:entity` es interactivo: se le pasan las respuestas por stdin o el agente se cuelga.
   El hook bloquea crear archivos nuevos en `src/Entity/` y escribir en `migrations/`.
3. **Acceso a datos solo vía Repositorios**, con métodos nombrados por intención.
   Cero DQL/QueryBuilder en controllers o services.
4. Lógica de negocio en **Services**. Controllers delgados y single-action (`__invoke`).
5. CRUD estándar → API Platform con operaciones explícitas. Nunca `#[ApiResource]` pelado.
   Lógica al leer/escribir → State Provider/Processor, que delega en un Service.
6. Toda entrada validada con constraints; **ningún campo sale sin grupo de serialización**.
7. Inyección por constructor + autowiring. Nada de `new` para servicios.
8. Permisos object-level **siempre con Voter**, nunca con un `if ($user !== $obj->getOwner())`.
9. Mailer, Messenger y Mercure son opcionales: solo si el usuario los pidió, y explicándole
   antes qué hace cada uno.
10. Login por **`username`**, no `email`. **No hay refresh token**: el access dura una hora y
    al caducar el cliente vuelve a autenticarse.

## Flujo de capas (unidireccional)

```
HTTP (operación API Platform | Controller)
  → Service (reglas, transacciones)
    → Repository (consultas nombradas)
      → Entity (invariantes simples)
```

Un Repository nunca llama a un Service. Una Entity no conoce nada.

## Comandos canónicos

```bash
# make:entity es INTERACTIVO. Respuestas por tubería, en orden:
#   clase, y por cada campo: nombre, tipo, [longitud si es string], nullable. Línea vacía cierra.
printf 'Product\nname\nstring\n255\nno\n\n' | php bin/console make:entity
php bin/console make:migration
php bin/console doctrine:migrations:migrate --no-interaction
php bin/console doctrine:schema:validate     # antes de cada commit
php bin/console cache:clear
```

`doctrine:schema:update` está **bloqueado por hook**. Si lo necesitas, la respuesta es
`make:migration`.

## Antes de cerrar una tarea de backend

```bash
bash .claude/scripts/gate-backend.sh
```

Y verifica a mano lo que el gate no ve: grupos de serialización sin fugas (`password`, tokens,
relaciones internas), filtros declarados por recurso, `409` para conflictos de negocio,
timestamps en la entidad nueva, y ausencia de N+1 en las colecciones que tocaste.
