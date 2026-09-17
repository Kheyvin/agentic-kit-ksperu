---
description: Verifica una tarea en el navegador y deja sus tests Playwright
argument-hint: "[TASK-015 | smoke]"
---

Invoca a `qa` con: "Verifica $ARGUMENTS" (si está vacío: "Verifica smoke").

Lo normal es lanzarlo sobre la tarea de frontend de una funcionalidad cuando su backend y su
frontend están `hecha`. Cuando vuelva, muestra al usuario los criterios verificados, los que
fallan con su evidencia y el resultado de la suite. Si algo falla por el código, propón la tarea
de corrección con `/planificar <descripción del fallo>`; el test se queda rojo hasta entonces.
