---
description: Audita el código generado en busca de bugs y violaciones del estándar
argument-hint: "[TASK-014 | vacío = diff actual]"
---

Invoca a `code-auditor` sobre: $ARGUMENTS

1. Obtén el diff (`git diff` o el de la tarea indicada).
2. Corre el gate correspondiente a la instancia de la tarea y recoge la salida:
   `bash .claude/scripts/gate-backend.sh <instancia>` o `gate-frontend.sh <instancia>`.
3. Revisa contra la skill `code-review` y los estándares del stack.
4. Escribe `docs/audits/AUDIT-XXX.md` con la plantilla del kit.
5. Emite veredicto: APROBADO · APROBADO CON OBSERVACIONES · RECHAZADO.

Si el cambio toca autenticación, permisos, datos personales, subida de archivos o secretos,
invoca además a `security-reviewer`. Si toca UI, a `a11y-reviewer`. Si toca listados o
consultas nuevas, a `performance-reviewer`.

Los gates son rápidos a propósito: no corren el build ni la auditoría de dependencias. Si el
cambio toca `package.json` o `composer.json`, corre además
`bash .claude/scripts/deep-check.sh`.

Recuerda: código limpio no es código correcto. Si terminas sin hallazgos, revisa otra vez los
casos borde —lista vacía, sin permiso, campo nulo, peticiones simultáneas— antes de aprobar.
