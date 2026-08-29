---
name: project-bootstrap
description: Crear el proyecto desde cero — backend Symfony 8.1 headless con API Platform y JWT, y/o SPA Vue 3 con Vite — e inicializar el árbol docs/ del kit. Úsalo al arrancar un repositorio nuevo, al añadir una instancia que falte (otro backend u otro frontend) o cuando falte docs/state.yaml.
---

# Bootstrap del proyecto

Todo lo que crea esta skill es **entorno de desarrollo**. No hay producción, no hay CI y no hay
despliegue: de subir el proyecto se encarga el usuario por su cuenta. No propongas Docker,
workflows ni infraestructura, ni siquiera "para más adelante".

## Paso 0 — Pregunta qué se construye. Nunca lo asumas

Haz esta pregunta **siempre**, incluso si el nombre del repositorio parece sugerir la respuesta:

| Forma | Qué se crea |
|---|---|
| **Solo backend** | Una API Symfony. El cliente lo construye otro o ya existe |
| **Solo frontend** | Una SPA Vue que consume una API ajena |
| **Headless (por defecto)** | Una API Symfony + una SPA Vue que la consume |
| **Multi-instancia** | Varios backends y/o varios frontends en el mismo repositorio |

Luego pregunta **el nombre de cada instancia**, una por una. Convención obligatoria:

- Una sola instancia de cada capa → `backend/` y `frontend/`.
- Varias → `<nombre>_backend` y `<nombre>_frontend`: `ventas_backend`, `admin_backend`,
  `cliente_frontend`, `admin_frontend`. **Ninguna se queda con el nombre genérico**: si hay dos
  backends, los dos llevan prefijo, para que nadie tenga que recordar cuál era "el backend".

Con multi-instancia, cada backend nuevo se crea **repitiendo la receta entera**, no copiando la
carpeta anterior: copiar arrastra el `JWT_SECRET`, la base de datos y las migraciones ya
aplicadas del primero.

`paths.sh` detecta las instancias solas leyendo el disco. Solo si tu estructura es rara, fíjalas
a mano en `.claude/project.json`.

## 1. Backend — Symfony 8.1

```bash
symfony new backend --version="8.1.*"
cd backend
```

### 1.1 ORM

```bash
composer require symfony/orm-pack
```

### 1.2 MakerBundle (los comandos `make:`)

```bash
composer require symfony/maker-bundle --dev
```

### 1.3 HttpFoundation (para `Request`)

```bash
composer require symfony/http-foundation
```

### 1.4 API Platform

```bash
composer require api
```

### 1.5 Base de datos — SQLite, siempre

En desarrollo **siempre SQLite**. Fija esto en `.env` antes de crear nada:

```dotenv
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"
```

```bash
php bin/console doctrine:database:create
```

Si el usuario pide otro motor, **avísale explícitamente de que tiene que cambiar `DATABASE_URL`
en `.env`** y de que las migraciones ya generadas pueden no ser portables entre motores.

### 1.6 Seguridad y entidad `User`

```bash
composer require symfony/security-bundle
```

`make:user` es **interactivo**. Se le pasan las respuestas por stdin o el agente se cuelga
esperando:

```bash
printf 'User\nyes\nusername\nyes\n' | php bin/console make:user
```

Esas cuatro respuestas son, en orden: clase `User` · guardar en base de datos vía Doctrine ·
**la propiedad única de display es `username`** (no `email`) · sí, la app hashea contraseñas.

```bash
php bin/console make:migration
php bin/console doctrine:migrations:migrate --no-interaction
```

### 1.7 Autenticación JWT

```bash
composer require lexik/jwt-authentication-bundle
```

El bundle ya modifica archivos por su cuenta; eso es esperado y no hay que deshacerlo.
Quedan tres ajustes a mano.

`config/packages/security.yaml` — los firewalls:

```yaml
    firewalls:
        login:
            pattern: ^/api/login
            stateless: true
            json_login:
                check_path: /api/login_check
                success_handler: lexik_jwt_authentication.handler.authentication_success
                failure_handler: lexik_jwt_authentication.handler.authentication_failure

        api:
            pattern:   ^/api
            stateless: true
            jwt: ~
```

`config/routes.yaml` — la ruta que consume el firewall:

```yaml
api_login_check:
    path: /api/login_check
```

`config/packages/lexik_jwt_authentication.yaml` — para que hable con API Platform:

```yaml
lexik_jwt_authentication:
    # ...
    api_platform:
        check_path: /api/login_check
        username_path: username
        password_path: password
```

Y las claves:

```bash
php bin/console lexik:jwt:generate-keypair
```

**No hay refresh token.** El kit no lo instala ni lo contempla. Si el usuario lo pide
explícitamente, se añade entonces y se documenta en el contrato de esa instancia.

### 1.8 Datos de prueba

```bash
composer require --dev orm-fixtures
```

`src/DataFixtures/AppFixtures.php` con un usuario conocido — lo consumen los tests E2E:

```php
public function load(ObjectManager $manager): void
{
    $user = new User();
    $user->setUsername('admin');

    $password = $this->hasher->hashPassword($user, 'pass_1234');
    $user->setPassword($password);

    $manager->persist($user);
    $manager->flush();
}
```

`UserPasswordHasherInterface $hasher` se inyecta por constructor.

```bash
php bin/console doctrine:fixtures:load --no-interaction
```

### 1.9 Verificación: el login devuelve un token

```bash
symfony server:start -d
```

Coge el puerto `:8000` si está libre y el siguiente si no. **Lee el puerto real que imprime el
servidor** antes de probar; no lo des por hecho.

```bash
# Linux, macOS y Git Bash en Windows
curl -X POST -H "Content-Type: application/json" \
  https://localhost:8000/api/login_check \
  -d '{"username":"admin","password":"pass_1234"}'
```

```
REM cmd.exe de Windows
curl -X POST -H "Content-Type: application/json" https://localhost:8000/api/login_check --data {\"username\":\"admin\",\"password\":\"pass_1234\"}
```

Respuesta correcta — el valor será distinto, lo que importa es la forma:

```json
{ "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXUyJ9.eyJleHAiOjE0MzQ3Mjc1MzYsInVzZXJuYW1lIjoia29ybGVvbiJ9.nh0L_wuJy6ZKIQWh6OrW5hdLkviTs1_bau2Gq" }
```

Si sale `401`, el problema está en `username_path` o en las fixtures. Si sale `404`, en
`config/routes.yaml`. El backend no se da por terminado hasta que este `curl` devuelve `token`.

## 2. Frontend — Vite + Vue 3

```bash
npm create vite@latest frontend -- --template vue
cd frontend
npm install
npm install axios vue-router pinia
npm install tailwindcss @tailwindcss/vite
npm install -D @playwright/test
npx playwright install chromium
```

`vite.config.js`:

```js
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    vue(), tailwindcss()
  ],
})
```

Y en `src/style.css` (el que genera la plantilla de Vite), como primera línea:

```css
@import 'tailwindcss';
```

```bash
npm run dev
```

Levanta en `http://localhost:5173`. Con varios frontends, Vite coge el siguiente puerto libre
para cada uno: anota cuál es cada cual, porque los tests E2E lo necesitan.

Después, el árbol de carpetas obligatorio del estándar `frontend-vite` (atoms/molecules/
organisms, `services/`, `stores/`, `composables/`, `constants/`, `router/`).

## 3. Árbol de documentación

```bash
mkdir -p docs/adr docs/stories docs/tasks docs/mockups docs/audits docs/qa docs/contracts
```

- `docs/state.yaml` ← copia de `.claude/templates/STATE.yaml`, con las instancias rellenadas.
- `docs/contracts/<instancia>.md` ← copia de `.claude/templates/CONTRACT.md`, **uno por cada
  backend**. Con `ventas_backend` y `admin_backend` hay dos contratos independientes.

Sin `state.yaml` y sin al menos un contrato, el resto del kit no funciona.

```bash
bash .claude/scripts/gate-contract.sh   # registra el lock inicial de cada contrato
```

## 4. Verificación de arranque

```bash
source .claude/scripts/paths.sh && echo "$LAYOUT | $N_BACKENDS backends | $N_FRONTENDS frontends"
bash .claude/scripts/gate-backend.sh
bash .claude/scripts/gate-frontend.sh
```

Las instancias detectadas deben coincidir con las que creaste. Si `LAYOUT` sale
`sin-inicializar`, los gates se omiten y **todo parecerá verde sin haber comprobado nada**:
arréglalo antes de seguir.

Ninguna tarea empieza con el bootstrap en rojo.

## Paquetes opcionales — se preguntan, no se instalan por defecto

Si durante el discovery aparece una de estas necesidades, explica al usuario qué hace el
paquete y **pregunta antes de instalarlo**:

| Paquete | Para qué | Cuándo aparece |
|---|---|---|
| `symfony/mailer` | Enviar correo: alta de usuario, recuperación de contraseña, notificaciones | El usuario menciona avisos por email |
| `symfony/messenger` | Colas y trabajos en segundo plano; saca de la petición HTTP lo que tarda | Importaciones, informes pesados, envíos masivos |
| `mercure` | Empujar cambios al navegador en tiempo real sin que el frontend pregunte | Paneles en vivo, notificaciones instantáneas, chat |

Ninguno se instala "por si acaso": cada uno añade configuración e infraestructura que hay que
mantener.
