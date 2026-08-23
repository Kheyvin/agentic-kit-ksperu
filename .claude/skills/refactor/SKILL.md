---
name: refactor
description: Refactorizar sin cambiar comportamiento — criterios de olor de código para este stack y reglas de seguridad del cambio. Úsalo cuando se pida limpiar, simplificar o reestructurar código existente, o al detectar duplicación durante una revisión.
---

# Refactor

## Regla absoluta

**El refactor no cambia comportamiento.** Los tests que pasaban antes pasan después,
**sin tocar los tests**. Si tienes que modificar un test para que el refactor pase, no estás
refactorizando: estás cambiando el sistema, y eso es otra tarea con su propia historia.

Si no hay test que cubra la zona, el primer paso del refactor es escribirlo. Refactorizar sin
red es reescribir a ciegas.

## Olores que justifican refactor aquí

**Backend**
- El mismo QueryBuilder repetido en dos repositorios → método compartido o criteria.
- Service que supera ~200 líneas o cuyo nombre incluye "Manager"/"Helper"/"Utils": no tiene una
  responsabilidad, tiene un cajón.
- Controller que hace algo más que validar → delegar → responder.
- Cadena de `if` sobre un campo de estado → enum + polimorfismo o máquina de estados.
- Lógica de negocio filtrada dentro de una entidad.

**Frontend**
- Cadena de utilidades Tailwind repetida en ≥2 sitios → extraer atom/molecule (nunca `@apply`).
- Lógica repetida en ≥2 componentes → composable.
- Componente por encima de 200 líneas → dividir en molecules/organisms.
- Store con estado efímero de una sola vista → mover a composable.
- Organism que consume stores sin ser transversal → convertir en dumb con props/emits.

## Lo que NO se refactoriza

Código que funciona, nadie toca y nadie va a tocar. La deuda solo importa donde hay tráfico:
refactoriza lo que estás a punto de modificar, no lo que te incomoda leer.

Tampoco se refactoriza "de paso" dentro de una tarea de funcionalidad: ensucia el diff y hace
imposible revisar. Se anota en `docs/state.yaml` bajo `deuda:` y se convierte en tarea propia.

## Procedimiento

1. Verifica cobertura de la zona; si falta, escribe el test primero (y commitea aparte).
2. Corre la suite y **guarda la salida** como línea base.
3. Refactoriza en pasos pequeños, con la suite en verde entre paso y paso.
4. Compara con la línea base: mismos tests, mismo resultado.
5. Commit separado del de funcionalidad, con mensaje `refactor:`.
