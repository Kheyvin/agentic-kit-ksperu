---
name: code-review
description: Reglas de revisión de código y criterio de severidad para este stack (Symfony/API Platform y Vue/Pinia/Tailwind). Úsalo al auditar un diff, revisar código recién generado por otro agente, o decidir si un hallazgo bloquea la entrega.
---

# Revisión de código

Revisa **el diff**, no el repositorio entero. Un hallazgo fuera del diff se anota como deuda,
no bloquea la tarea.

## Severidad — el único criterio que importa

| Nivel | Definición | Efecto |
|---|---|---|
| **BLOQUEANTE** | Rompe seguridad, corrompe datos, viola el contrato API, o incumple una regla de oro del estándar | La tarea no se cierra |
| **MAYOR** | Bug probable en un caso borde real, o deuda que costará caro revertir | Se arregla en esta tarea salvo justificación escrita |
| **MENOR** | Estilo, nombres, duplicación tolerable | Se anota, no bloquea |

Si dudas entre BLOQUEANTE y MAYOR: ¿se puede desplegar esto sin riesgo de pérdida o fuga de
datos? Si sí, es MAYOR.

## Bloqueantes de backend

- Consulta (`createQueryBuilder`, DQL) fuera de `src/Repository/`.
- Lógica de negocio en un controller o en una entidad.
- Campo expuesto sin grupo de serialización, o fuga de `password`/hash/token/campo interno.
- `#[ApiResource]` sin operaciones explícitas, o filtro no declarado.
- Permiso object-level resuelto con un `if` en vez de un Voter.
- Escritura sin constraints de validación, o error de validación devuelto sin `violations[]`.
- Excepción genérica `\Exception` lanzada desde un service.
- Concatenación de parámetros en una query (inyección).
- Migración editada a mano o `schema:update` en el flujo.
- `500` en producción devolviendo traza o mensaje interno.

## Bloqueantes de frontend

- `import axios` en un componente, vista o layout.
- Lógica de negocio dentro de un componente de presentación.
- Un atom que importa store, service o router.
- Ruta no lazy, o `meta` incompleto (`requiresAuth`, `roles`, `layout`, `title`).
- Formato hydra o RFC 7807 manejado fuera de `services/http/`.
- Color de marca hardcodeado en vez de token de `@theme`.
- Vista con datos que no implementa los cuatro estados.
- `catch` que silencia el error sin propagar `AppError` ni notificar.
- Doble submit posible en un formulario; `violations` no mapeadas por `propertyPath`.
- Refresh de token sin cola compartida o sin guarda anti-bucle (`_retry`).

## Formato del hallazgo

```markdown
### [BLOQUEANTE] Consulta fuera de Repository
`src/Service/Catalog/ProductFinder.php:34`

El service construye el QueryBuilder directamente, saltándose la capa de repositorio.

**Actual**
```php
$qb = $this->em->createQueryBuilder()->select('p')->from(Product::class, 'p');
```

**Propuesto**
```php
return $this->products->findActiveByCategory($category);
```
con `findActiveByCategory()` nuevo en `ProductRepository`.

**Por qué bloquea:** el estándar prohíbe DQL fuera de repositorios; además esta consulta
se duplicará en cuanto otro service necesite lo mismo.
```

Cada hallazgo lleva archivo:línea, el código actual, el propuesto y **por qué importa**.
Un hallazgo sin ubicación exacta es inaccionable y no cuenta.

## Lo que NO es tu trabajo

No reescribas el código: propón. No opines sobre decisiones ya tomadas en un ADR —si crees que
el ADR está mal, dilo aparte. No inventes reglas que no estén en los estándares del proyecto.
