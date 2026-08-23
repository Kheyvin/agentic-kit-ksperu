# AUDIT-XXX — <tarea o rango auditado>

- **Fecha:** 
- **Tarea:** TASK-XXX
- **Auditor:** code-auditor
- **Alcance del diff:** N archivos, `git diff <ref>`

## Veredicto

**APROBADO** | **APROBADO CON OBSERVACIONES** | **RECHAZADO**

Una frase de justificación.

## Gate

```
# salida de .claude/scripts/gate-*.sh
```

Resultado: verde / rojo

## Hallazgos

### [BLOQUEANTE] <título>
`ruta/archivo.php:34`

Qué pasa y en qué circunstancia se manifiesta.

**Actual**
```php
```

**Propuesto**
```php
```

**Por qué bloquea:** consecuencia concreta.

---

### [MAYOR] <título>
`ruta/archivo.vue:88`

...

---

### [MENOR] <título>
`ruta/archivo.js:12`

...

## Criterios de aceptación

- [x] AC-1 — verificado con `<comando>`
- [ ] AC-2 — **no cumplido**: solo funciona en el camino feliz; con la lista vacía lanza error

## Casos borde revisados

Lista vacía · usuario sin permiso · campo nulo · peticiones simultáneas · valores límite.
Indica cuáles se comprobaron y cuáles no se pudieron comprobar.

## Deuda a anotar en state.yaml

- 
