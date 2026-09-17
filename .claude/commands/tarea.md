---
description: Ejecuta una tarea con el subagente que corresponde y la cierra con el gate en verde
argument-hint: "TASK-014 | siguiente"
---

Tarea: $ARGUMENTS

Tú orquestas; no programas. No leas el código de las instancias ni intentes arreglar el gate:
todo eso lo hace el subagente con su propio contexto.

1. Si es `siguiente`, resuélvelo con `bash .claude/scripts/estado.sh --siguiente`. Lee
   `docs/tasks/<id>.md` (solo ese archivo). Si no existe, dilo y para.
2. `depende_de`: todas deben estar `hecha` (`bash .claude/scripts/estado.sh`). Si no, dilo y para.
3. `bash .claude/scripts/estado.sh --marcar <id> en_curso`.
4. Invoca al subagente de `agente:` con **una sola línea**: "Ejecuta docs/tasks/<id>.md".
   Sin resumen, sin contexto extra: si le falta algo, la tarea está mal escrita y se arregla ahí.
5. Al volver, si el agente marcó la tarea `bloqueada`, transmite su pregunta al usuario y para.
   Si no, **corre tú el gate** de la instancia:
   `bash .claude/scripts/gate-backend.sh <instancia>` o `bash .claude/scripts/gate-frontend.sh <instancia>`.
   - VERDE → sigue.
   - ROJO → reenvía **una vez** al mismo subagente: "Ejecuta docs/tasks/<id>.md. El gate falla
     con: <últimas 25 líneas de la salida>". Vuelve a correr el gate. Si sigue rojo:
     `bash .claude/scripts/estado.sh --marcar <id> bloqueada "gate rojo: <primera línea del fallo>"`,
     enséñale la salida al usuario y para. **No hay tercer intento.**
6. Si la tarea tiene `revision: sí`, invoca a `reviewer`: "Revisa docs/tasks/<id>.md". Con
   bloqueantes, una sola pasada de corrección con el subagente original ("Ejecuta
   docs/tasks/<id>.md: corrige solo los BLOQUEANTES de la sección Revisión") y el gate otra vez.
   Sin segunda pasada: si quedan bloqueantes, la tarea queda `bloqueada` y se lo cuentas al usuario.
7. `bash .claude/scripts/estado.sh --marcar <id> hecha`. Informa en ≤ 8 líneas con el resumen
   del subagente. Propón el commit `git add -A && git commit -m "<id>: <título>"` y ejecútalo
   solo si el usuario lo confirma (o ya dijo en esta sesión que commitees al cerrar).
8. Propón la siguiente: `bash .claude/scripts/estado.sh --siguiente`.
