# Receta de bootstrap — backend Symfony 8.1 headless

Parámetros que recibes: la **carpeta** de la instancia (`backend` o `<nombre>_backend`) y la
**conexión de BD** (por defecto SQLite). Ejecuta los pasos en orden desde la raíz del repositorio.
Criterio de terminado: el `curl` del paso 8 devuelve `token` y el gate está en verde.
Todo es entorno de desarrollo: sin Docker, CI ni despliegue.

## 1. Proyecto y paquetes

```bash
symfony new <dir> --version="8.1.*"
cd <dir>
composer require symfony/orm-pack api symfony/security-bundle nelmio/cors-bundle
composer require --dev symfony/maker-bundle orm-fixtures
```

## 2. Base de datos

En `.env`, sustituye la línea `DATABASE_URL` por la conexión indicada. Por defecto:

```dotenv
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"
```

Si el usuario dio otro motor, usa su cadena tal cual y avísale de que las migraciones que se
generen dependen de ese motor. Luego: `php bin/console doctrine:database:create`
(en SQLite crea el archivo; en otros motores necesita el servidor arrancado).

## 3. Usuario y contraseña

`make:user` es interactivo: las cuatro respuestas son clase `User`, guardar en BD vía Doctrine,
identificador **`username`** (no email) y sí hashear contraseñas.

```bash
printf 'User\nyes\nusername\nyes\n' | php bin/console make:user
```

Edita `src/Entity/User.php`: añade `#[ORM\HasLifecycleCallbacks]`, `use TimestampableTrait`
(créalo antes con la sección 4 de `patrones.md`) y grupos `user:read` en `id`, `username`,
`roles`; **`password` sin grupo**. Después:

```bash
php bin/console make:migration
php bin/console doctrine:migrations:migrate --no-interaction
```

## 4. JWT

```bash
composer require lexik/jwt-authentication-bundle
php bin/console lexik:jwt:generate-keypair
```

Deja `config/packages/security.yaml`, `config/routes.yaml` y
`config/packages/lexik_jwt_authentication.yaml` exactamente como la sección 1 de `patrones.md`
(firewalls `login` y `api`, `access_control`, `token_ttl: 3600`, bloque `api_platform`).
El bundle ya modificó archivos por su cuenta: es lo esperado. **No hay refresh token.**

## 5. API Platform y CORS

`config/packages/api_platform.yaml` y `config/packages/nelmio_cors.yaml` como las secciones 2
y 3 de `patrones.md`. En `.env`, `CORS_ALLOW_ORIGIN` con la regex de localhost de esa sección.

## 6. Base del kit

- `src/Entity/Trait/TimestampableTrait.php` (sección 4).
- `src/Controller/Api/MeController.php` (sección 8): `GET /api/me`.
- `src/DataFixtures/AppFixtures.php` (sección 9) y `php bin/console doctrine:fixtures:load --no-interaction`.

## 7. Arranque

```bash
symfony server:start --no-tls -d
```

Lee el puerto que imprime (normalmente `8000`; si está ocupado, el siguiente) y úsalo abajo.

## 8. Verificación

```bash
curl -s -X POST -H "Content-Type: application/json" http://localhost:8000/api/login_check \
  -d '{"username":"admin","password":"pass_1234"}'
```

Debe devolver `{"token":"eyJ..."}`. Si sale `401`, revisa `username_path` y las fixtures; si
`404`, `config/routes.yaml`. Luego, con ese token:

```bash
curl -s -H "Authorization: Bearer <token>" http://localhost:8000/api/me
```

Debe devolver `{"id":1,"username":"admin","roles":["ROLE_ADMIN","ROLE_USER"]}`.

## 9. Gate

```bash
cd .. && bash .claude/scripts/gate-backend.sh <dir>
```

Verde antes de devolver el control. En la respuesta: puerto real, salida del `curl` de login y
del gate, y cualquier desviación de esta receta.

## Paquetes que se preguntan (nunca por defecto)

`symfony/mailer` (correo), `symfony/messenger` (colas y trabajos en segundo plano), `mercure`
(tiempo real). Solo si el usuario los pidió explícitamente.
