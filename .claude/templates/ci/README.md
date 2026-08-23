# Plantillas de CI — opcionales, NO instaladas

El kit no asume ninguna CI. Estas plantillas están aquí para el día que decidas.

**La regla que hace esto barato:** la CI no define comprobaciones propias, solo ejecuta los
mismos `.claude/scripts/gate-*.sh` que corres en local. Si un gate debe cambiar, cambias el
script y la CI hereda el cambio. Una CI que duplica reglas se desincroniza del local en semanas
y acabas con dos definiciones de "correcto".

Mientras no tengas CI, los gates ya se ejecutan por hook en cada tarea. **No estás sin red**:
la CI solo añade que se corran también cuando no eres tú quien empuja.

Para activar: copia el archivo a su ruta (`.github/workflows/ci.yml` o `.gitlab-ci.yml`),
ajusta versiones y servicios, y actualiza el campo `ci` de `.claude/project.json`.
