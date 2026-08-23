---
name: release
description: Preparar una versión — versionado semántico, CHANGELOG desde commits, checklist previo y etiquetado. Úsalo al cerrar un lote de historias, al preparar un despliegue o cuando se pida generar el changelog.
---

# Release

## Versionado semántico

- **MAJOR**: rompe el contrato API o exige intervención manual al actualizar.
- **MINOR**: funcionalidad nueva compatible.
- **PATCH**: corrección sin cambio de contrato.

Un cambio en `docs/CONTRACT.md` que altere una respuesta existente es MAJOR, aunque el diff sea
de tres líneas. El tamaño del diff no determina la versión; el impacto en quien consume, sí.

## Checklist previo (todo o nada)

```bash
bash .claude/scripts/gate-contract.sh
bash .claude/scripts/gate-backend.sh
bash .claude/scripts/gate-frontend.sh
npx playwright test
```

Los gates se adaptan solos al layout: si el repositorio no tiene frontend, ese gate se omite
en vez de fallar.

- [ ] Ambos gates en verde y suite E2E completa en verde.
- [ ] `docs/state.yaml` sin tareas `en_curso` ni `bloqueada` dentro del alcance.
- [ ] Migraciones aplicadas y `doctrine:schema:validate` limpio.
- [ ] Sin secretos en el diff; `.env.example` cubre toda variable nueva.
- [ ] CHANGELOG actualizado y ADRs del lote en estado `aceptado`.
- [ ] Rollback pensado y escrito: qué migración revertir y cómo.

## CHANGELOG

Se genera desde los commits del rango pero **se reescribe en lenguaje de usuario**. Agrupa en
Añadido / Cambiado / Corregido / Eliminado / Seguridad. Un commit de refactor puro no aparece:
no cambió nada para quien usa el sistema.

```bash
git log --oneline v1.2.0..HEAD --no-merges
```

## Etiquetado

```bash
git tag -a v1.3.0 -m "v1.3.0 — listado de productos con filtros persistentes"
git push origin v1.3.0
```

Tras el tag: mueve las historias del lote a `estado: hecha` en sus YAML, cierra sus tareas y
deja `docs/state.yaml` reflejando el nuevo punto de partida.

## Lo que nunca se hace en un release

Meter "un cambio más" después de que los gates pasaron. Si entra código nuevo, los gates se
vuelven a correr enteros. Un release es una foto verificada, no una intención.
