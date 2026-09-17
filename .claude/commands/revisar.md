---
description: Revisión de código, seguridad, contrato y accesibilidad sobre el diff de una tarea
argument-hint: "[TASK-014 | vacío = diff sin commitear]"
---

Invoca a `reviewer` con: "Revisa $ARGUMENTS" (si está vacío: "Revisa el diff sin commitear,
`git diff HEAD`").

Cuando vuelva, muestra al usuario su lista tal cual (veredicto y hallazgos, una línea cada uno)
y nada más. Si hay bloqueantes, propón `/tarea <id>` para que el subagente original los corrija;
no los corrijas tú. Las notas no generan trabajo salvo que el usuario lo pida.
