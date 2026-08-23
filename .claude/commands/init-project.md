---
description: Crea el proyecto (Symfony 8.1 y/o Vite+Vue) e inicializa el árbol docs/ del kit
argument-hint: "[nombre-proyecto]"
---

Inicializa el proyecto siguiendo la skill `project-bootstrap`.

Proyecto: $ARGUMENTS

1. **Pregunta primero el layout** — no lo asumas: monorepo (`api/` + `app/`), plano,
   solo-backend, solo-frontend o repos separados. Si el usuario duda y trabaja solo,
   recomienda monorepo y explica por qué: el contrato API no puede desincronizarse.
2. Pregunta también `app_type`: `system` o `landing`. Determina si GSAP existe en el proyecto.
3. Crea la estructura elegida:
   - Backend: `symfony new <dir> --version="8.1.*" --webapp=false` + dependencias de la skill.
   - Frontend: `npm create vite@latest <dir> -- --template vue` + Vue Router, Pinia, Axios,
     Tailwind v4, Playwright.
4. Crea `docs/` con `adr/ stories/ tasks/ mockups/ audits/ qa/`.
5. Copia `.claude/templates/STATE.yaml` → `docs/state.yaml` y
   `.claude/templates/CONTRACT.md` → `docs/CONTRACT.md`. Rellena `proyecto.layout` y
   `proyecto.app_type` con lo respondido.
6. `chmod +x .claude/scripts/*.sh` y comprueba la detección:
   ```bash
   source .claude/scripts/paths.sh && echo "$LAYOUT | $BACKEND_DIR | $FRONTEND_DIR"
   ```
7. `bash .claude/scripts/gate-contract.sh` para registrar el lock inicial.
8. Verifica que cada capa arranca limpia antes de seguir.

**No crees CI, Docker ni scripts de despliegue.** Quedan como decisiones pendientes en
`state.yaml`; el kit ya corre los gates por hook en local.

Termina proponiendo `/discovery`.
