---
name: project-bootstrap
description: Crear el proyecto desde cero — Symfony 8.1 headless y/o SPA Vue 3 con Vite — e inicializar el árbol docs/ del kit. Úsalo al arrancar un repositorio nuevo, al añadir la mitad que falte (solo backend o solo frontend) o cuando falte docs/state.yaml.
---

# Bootstrap del proyecto

## Paso 0 — Elegir layout (pregúntalo, no lo asumas)

El kit funciona con cualquiera de estos cuatro. `paths.sh` los detecta solo; lo único que
cambia es dónde vive cada capa.

| Layout | Estructura | Cuándo |
|---|---|---|
| **monorepo** | `api/` + `app/` hermanas | Por defecto. Un solo repo, un solo historial, contrato imposible de desincronizar |
| **plano** | Symfony y Vite en la raíz | Proyectos pequeños o cuando Symfony sirve la SPA |
| **solo-backend** / **solo-frontend** | una capa | La otra la construye alguien más o ya existe |
| **repos-separados** | dos repositorios | Equipos o despliegues independientes |

**Si eliges repos separados**, hay una consecuencia que debes aceptar antes: el contrato API
puede divergir sin que nada avise. Por eso `.claude/` y `docs/` se copian a **ambos** repos y
`gate-contract.sh` compara el hash de `docs/CONTRACT.md`. Si los dos lock no coinciden, hay un
bug de integración esperando. Con monorepo este problema no existe — es la razón principal
para preferirlo cuando trabajas solo.

Registra la elección en `docs/state.yaml` (`proyecto.layout`) y, si tu estructura es inusual,
fija las rutas a mano en `.claude/project.json`.

## 1. Backend — Symfony 8.1

```bash
symfony new api --version="8.1.*" --webapp=false
cd api
composer require api-platform/symfony api-platform/doctrine-orm
composer require lexik/jwt-authentication-bundle gesdinet/jwt-refresh-token-bundle
composer require symfony/security-bundle nelmio/cors-bundle
composer require symfony/serializer symfony/validator symfony/property-info symfony/property-access
composer require symfony/messenger symfony/doctrine-messenger
composer require --dev symfony/maker-bundle doctrine/doctrine-fixtures-bundle
php bin/console lexik:jwt:generate-keypair
```

`symfony/mailer` **no se instala aquí**: solo si el cliente pidió correos (§10 del estándar).

Configuración inmediata, antes de la primera entidad:
- `config/packages/api_platform.yaml` → `hydra_prefix: false`, `pagination_items_per_page: 20`.
- `config/packages/nelmio_cors.yaml` → origen exacto de la SPA vía `CORS_ALLOW_ORIGIN`.
- `.gitignore` → `config/jwt/*.pem`, `.env.local`.

## 2. Frontend — Vite + Vue 3

```bash
npm create vite@latest app -- --template vue
cd app
npm install
npm install vue-router pinia axios
npm install tailwindcss @tailwindcss/vite
npm install -D prettier prettier-plugin-tailwindcss
npm install -D playwright-core @playwright/test
npx playwright install chromium
```

GSAP **solo si `APP_TYPE === 'landing'`**. En sistemas de gestión no se instala (§9 del estándar).

Luego: `vite.config.js` con el plugin de Tailwind y el alias `@`, `src/styles/main.css` con
`@import "tailwindcss"` + bloque `@theme`, y el árbol de carpetas obligatorio del estándar
frontend. Añade a `package.json`: `"smoke": "node scripts/smoke.mjs"`, `"e2e": "playwright test"`.

## 3. Árbol de documentación

```bash
mkdir -p docs/adr docs/stories docs/tasks docs/mockups docs/audits docs/qa
```

Crea `docs/state.yaml` desde `.claude/templates/STATE.yaml` y `docs/CONTRACT.md` desde
`.claude/templates/CONTRACT.md`. Sin estos dos archivos el resto del kit no funciona.

## 4. Verificación de arranque

```bash
cd api && php bin/console doctrine:schema:validate --skip-sync && symfony server:start -d
cd ../app && npm run build && npm run dev
```

Ambos deben levantar limpios **antes** de escribir la primera línea de dominio. Si el bootstrap
no está verde, ninguna tarea puede empezar.

## Adaptación por layout

Los comandos de arriba asumen `api/` y `app/`. En layout **plano**, ejecútalos en la raíz
(`symfony new . --version="8.1.*"` sobre un directorio ya creado, y `npm create vite@latest .`).
En **solo-backend** omite el paso 2, pero `docs/CONTRACT.md` sigue siendo obligatorio: lo
consumirá otro cliente y sin él ese cliente adivina.

En **repos separados**, tras inicializar cada repo:

```bash
cp -r .claude docs ../otro-repo/     # ambos repos, mismo kit y mismo contrato
bash .claude/scripts/gate-contract.sh # registra docs/.contract.lock en los dos
```

El día que el contrato cambie, `gate-contract.sh` fallará en el repo que no se actualizó.
Ese fallo es la función, no un estorbo.

## Infraestructura: todavía no

No crees Dockerfile, workflow de CI ni scripts de despliegue en el bootstrap. Mientras
`infra.ci` e `infra.deploy` estén sin decidir en `state.yaml`, los gates corren por hook en
local y eso basta. Las plantillas esperan en `.claude/templates/ci/` para el día que haya
decisión.
