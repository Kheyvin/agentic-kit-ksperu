---
description: Prepara una versión — gates, CHANGELOG, versión semántica y tag
argument-hint: "[major|minor|patch]"
---

Invoca a `release-manager`. Tipo sugerido: $ARGUMENTS

1. Checklist completo: `gate-contract.sh`, `gate-backend.sh`, `gate-frontend.sh`, `npx playwright test`.
2. `docs/state.yaml` sin tareas `en_curso` ni `bloqueada` en el alcance.
3. Decide la versión por impacto en quien consume el contrato, no por tamaño del diff.
4. CHANGELOG desde `git log`, reescrito en lenguaje de usuario.
5. Plan de rollback escrito: qué migración se revierte y cómo.
6. Tag anotado. Historias del lote a `hecha`. `state.yaml` limpio.

Si algo está en rojo, para y repórtalo. No se etiqueta nada con un gate en rojo, y no entra
código nuevo después de que los gates pasaron.
