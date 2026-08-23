---
description: Audita el código generado en busca de bugs y violaciones del estándar
argument-hint: "[TASK-014 | vacío = diff actual]"
---

Invoca a `code-auditor` sobre: $ARGUMENTS

1. Obtén el diff (`git diff` o el de la tarea indicada).
2. Corre el gate correspondiente y recoge la salida.
3. Revisa contra la skill `code-review` y los estándares del stack.
4. Escribe `docs/audits/AUDIT-XXX.md` con la plantilla del kit.
5. Emite veredicto: APROBADO · APROBADO CON OBSERVACIONES · RECHAZADO.

Si el cambio toca autenticación, permisos, datos personales, subida de archivos o secretos,
invoca además a `security-reviewer`. Si toca UI, a `a11y-reviewer`. Si toca listados o
consultas nuevas, a `performance-reviewer`.

Recuerda: código limpio no es código correcto. Si terminas sin hallazgos, revisa otra vez los
casos borde —lista vacía, sin permiso, campo nulo, peticiones simultáneas— antes de aprobar.
