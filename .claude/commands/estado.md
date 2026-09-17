---
description: Estado real del proyecto, leído del disco
---

Corre `bash .claude/scripts/estado.sh` y `bash .claude/scripts/session-context.sh` y reporta:

- **Bloqueado** (va primero si hay algo): tarea y motivo.
- **En curso** y **siguiente** recomendada, con el comando exacto (`/tarea TASK-XXX`).
- Instancias detectadas. Si el layout es `sin-inicializar` y hay carpetas de código, avisa:
  los gates se están omitiendo.

No respondas de memoria ni leas más archivos. Si el disco contradice lo dicho en la
conversación, gana el disco y señala la diferencia.
