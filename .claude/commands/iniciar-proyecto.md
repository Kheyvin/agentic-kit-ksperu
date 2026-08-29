---
description: Crea el proyecto (Symfony 8.1 y/o Vite+Vue) e inicializa el árbol docs/ del kit
argument-hint: "[nombre-proyecto]"
---

Inicializa el proyecto siguiendo la skill `project-bootstrap`.

Proyecto: $ARGUMENTS

1. **Pregunta primero qué se construye** — no lo asumas:
   - solo backend · solo frontend · **headless** (API + SPA, por defecto) · multi-instancia.
   - Si hay varias instancias, pregunta **el nombre de cada una**, una por una. Convención:
     `<nombre>_backend` y `<nombre>_frontend`; con una sola de cada capa, `backend/` y
     `frontend/`. Si hay dos backends, **los dos llevan prefijo**.
   - Pregunta qué frontend consume qué backend: de ahí sale un contrato por backend.

2. Crea el backend con la receta completa de la skill, en este orden y sin saltarte pasos:
   `symfony new <dir> --version="8.1.*"` → `orm-pack` → `maker-bundle` → `http-foundation` →
   `api` → `DATABASE_URL` de SQLite en `.env` + `doctrine:database:create` → `security-bundle`
   + `make:user` (identificador **`username`**) → migración → `lexik/jwt-authentication-bundle`
   + los tres ajustes de YAML + `lexik:jwt:generate-keypair` → `orm-fixtures` con el usuario
   `admin`/`pass_1234` → arranque del servidor y **verificación con `curl` de que
   `/api/login_check` devuelve `token`**.

   Ese `curl` es el criterio de terminado del backend. Sin él, no está hecho.

3. Crea el frontend: `npm create vite@latest <dir> -- --template vue`, luego `axios`,
   `vue-router`, `pinia`, `tailwindcss @tailwindcss/vite`, el plugin en `vite.config.js`,
   `@import 'tailwindcss';` en `src/style.css`, y el árbol de carpetas del estándar.

4. Crea `docs/` con `adr/ stories/ tasks/ mockups/ audits/ qa/ contracts/`.

5. Copia `.claude/templates/STATE.yaml` → `docs/state.yaml` y rellena el bloque `instancias`
   con lo respondido. Copia `.claude/templates/CONTRACT.md` → `docs/contracts/<instancia>.md`,
   **uno por cada backend**.

6. `chmod +x .claude/scripts/*.sh` y comprueba la detección:
   ```bash
   source .claude/scripts/paths.sh && echo "$LAYOUT | $N_BACKENDS backends | $N_FRONTENDS frontends"
   ```
   Las instancias detectadas deben coincidir con las que creaste. Si sale `sin-inicializar`,
   los gates se omiten y todo parecerá verde sin haber comprobado nada: arréglalo antes de seguir.

7. `bash .claude/scripts/gate-contract.sh` para registrar el lock inicial de cada contrato.

8. Verifica que cada capa arranca limpia antes de seguir.

Si el usuario pide `symfony/mailer`, `symfony/messenger` o `mercure`, explícale primero qué hace
cada uno y **pregunta antes de instalar**. Ninguno entra "por si acaso".

**No crees CI, Docker ni scripts de despliegue**, ni los propongas. Todo esto es entorno de
desarrollo; de subir el proyecto se encarga el usuario.

Termina proponiendo `/descubrimiento`.
