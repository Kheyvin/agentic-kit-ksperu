---
description: Crea el proyecto (Symfony 8.1 y/o Vite + Vue 3) y el árbol docs/ del kit
argument-hint: "[nombre-proyecto]"
---

Proyecto: $ARGUMENTS

1. **Pregunta en un solo mensaje** y espera la respuesta:
   - Qué se construye: solo backend · solo frontend · **headless** (API + SPA, por defecto) · multi-instancia.
   - Nombre de cada instancia. Una de cada capa → `backend/` y `frontend/`. Varias → todas con
     prefijo: `ventas_backend`, `admin_backend`, `cliente_frontend`. Y qué frontend consume qué backend.
   - Motor de base de datos: **SQLite** por defecto; si quiere otro, que pase la cadena de conexión.
   - Plantilla de Vite: **`vue`** por defecto, o `vue-ts`.
   No preguntes por despliegue, CI, Docker ni servidores: no existen en este kit.

2. **Despacha el bootstrap en paralelo**, una llamada por instancia, sin ejecutar tú los comandos
   (la salida de composer y npm es larga y no te hace falta):
   - `backend-dev`: "Ejecuta la receta `.claude/skills/backend/reference/bootstrap.md` para la
     instancia `<dir>` con DATABASE_URL `<conexión>`."
   - `frontend-dev`: "Ejecuta la receta `.claude/skills/frontend/reference/bootstrap.md` para la
     instancia `<dir>`, plantilla `<vue|vue-ts>`, backend en `<url>/api`."

3. Cuando vuelvan, crea la documentación:
   - `docs/tasks/`, `docs/contracts/`, `docs/mockups/`.
   - `docs/BRIEF.md` desde `.claude/templates/BRIEF.md`, con la tabla de instancias rellenada y
     la primera decisión (motor de BD, plantilla).
   - `docs/contracts/<backend>.md` desde `.claude/templates/CONTRACT.md`, **uno por cada backend**,
     con los frontends que lo consumen.

4. Verifica: `bash .claude/scripts/session-context.sh` debe listar las instancias creadas. Si
   sale `sin-inicializar`, los gates se omitirían: arréglalo (nombres de carpeta o
   `.claude/project.json`) antes de seguir.

5. `bash .claude/scripts/gate-backend.sh` y `bash .claude/scripts/gate-frontend.sh`: los dos en
   verde. Si alguno está rojo, reenvía la salida al agente correspondiente una vez.

6. Termina con los puertos reales, las credenciales de prueba (`admin` / `pass_1234`) y:
   "Siguiente paso: `/planificar <lo que quieres construir>`".

Mailer, Messenger y Mercure no se instalan salvo que el usuario los pida.
