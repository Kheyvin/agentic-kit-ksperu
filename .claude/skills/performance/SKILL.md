---
name: performance
description: Revisión de rendimiento en Symfony/Doctrine y en la SPA Vue — N+1, índices, tamaño de bundle, renders y presupuestos de latencia. Úsalo al revisar listados, consultas nuevas, o cuando algo se perciba lento.
---

# Rendimiento

Mide antes de optimizar. Una optimización sin medición previa es una complicación gratuita.

## Presupuestos por defecto

| Métrica | Objetivo |
|---|---|
| Endpoint de listado (20 items) | < 200 ms servidor |
| Endpoint de detalle | < 100 ms servidor |
| Consultas SQL por request | ≤ 10 |
| Bundle JS inicial (gzip) | < 200 KB |
| LCP en la vista principal | < 2.5 s |

Si un cambio rompe un presupuesto, es un hallazgo MAYOR aunque "funcione".

## Backend

**N+1 — el 80% de los problemas reales.** Aparece siempre que una colección serializa una
relación. Detección:

```bash
php bin/console doctrine:query:sql "SHOW STATUS LIKE 'Questions'"
```
o el panel Doctrine del Profiler en dev: si una lista de 20 filas dispara 21+ consultas, hay N+1.

Solución: `addSelect` con join explícito en el método del repositorio. Nunca `fetch: 'EAGER'`
en la entidad —convierte el problema en global— ni resolverlo en el serializador.

Además:
- [ ] Índice en todo campo con filtro u orden declarado en API Platform.
- [ ] Paginación siempre activa. Un `GET` de colección sin límite es un incidente esperando.
- [ ] Conteos costosos: valorar `COUNT` aproximado o caché si la colección es grande.
- [ ] Operaciones pesadas (informes, envíos masivos) → Messenger, no request síncrono.
- [ ] Sin consultas dentro de bucles.

## Frontend

- [ ] Todas las rutas lazy: es lo que mantiene el bundle inicial bajo.
- [ ] `npm run build` y revisar el desglose; una dependencia pesada para un uso menor se
      importa dinámicamente o se sustituye.
- [ ] Búsquedas con debounce de 300 ms y `AbortController` cancelando la petición anterior:
      sin eso, teclear 8 letras lanza 8 requests y la respuesta que gana es aleatoria.
- [ ] `v-for` con `:key` estable — nunca el índice del array en listas que se reordenan.
- [ ] `computed` en vez de recalcular en el template.
- [ ] Listas de cientos de filas: paginar o virtualizar antes que renderizar todo.
- [ ] Imágenes dimensionadas y con `loading="lazy"` fuera del viewport.

## Medición

```bash
npm run build -- --report        # peso del bundle
npx playwright test --trace on   # tiempos reales de interacción
```

Anota la medición **antes y después** en la bitácora de la tarea. Una optimización sin ambas
cifras no se puede defender ni revertir con criterio.
