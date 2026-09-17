---
name: revision
description: Checklist para revisar el diff de una tarea en este stack — bugs reales, seguridad (auth, Voters, fugas de datos, IDOR), contrato API, accesibilidad y rendimiento — con dos severidades y sin relleno. Úsalo al revisar el código de una tarea o cuando el usuario pida /revisar.
---

# Revisión de un diff

Se revisa **el diff**, no el repositorio. Dos severidades y ninguna más:

- **BLOQUEANTE**: pierde o filtra datos, permite hacer algo sin permiso, rompe el contrato que
  consume el otro lado, o falla en un camino que un usuario recorre (lista vacía, sin permiso,
  campo nulo, doble envío, token caducado).
- **NOTA**: todo lo demás (estilo, nombres, duplicación, mejora posible). Se anota; no genera
  otra pasada.

Si no hay bloqueantes, se dice en una línea y se termina. **No se buscan hallazgos para
justificar la revisión.** Un hallazgo sin archivo y línea no cuenta.

## Orden

1. **Bugs reales.** Nulos no contemplados, off-by-one, transacción ausente cuando se tocan dos
   entidades, `catch` que traga el error, estado que no se limpia, promesa sin `await`.
2. **Seguridad** (bloqueante por defecto).
   - Operación de API Platform sin `security:`; permiso sobre objeto con `if` en vez de Voter.
   - Campo sin grupo de serialización, o `password`/hash/token/interno en un grupo de lectura.
   - IDOR: pedir por IRI el recurso de otro usuario devuelve `200`.
   - Escalada por payload: enviar `roles` u `owner` en el cuerpo cambia algo.
   - Parámetro concatenado en una consulta; subida de archivos sin MIME real ni límite de tamaño.
   - Secretos en el código; CORS con `*`; `v-html` con contenido del servidor sin sanear.
   - En el frontend, ocultar un botón no es seguridad: el endpoint tiene que rechazar.
3. **Contrato API.** Forma de la respuesta, códigos de estado, nombres de campos, fechas sin UTC,
   `violations` con otro shape, `docs/contracts/<instancia>.md` sin actualizar tras cambiar un
   endpoint, `itemsPerPage` distinto entre capas.
4. **Estándar** (NOTA salvo que cause un bug). Consulta fuera de `src/Repository/`; lógica en un
   controller o en una entidad; `axios` en un componente; atom que importa store o router; vista
   con datos sin los cuatro estados; ruta no lazy o `meta` incompleto; color a fuego en vez de
   token; componente de más de 200 líneas.
5. **Accesibilidad** (solo si el diff toca UI). `div` clicable sin `role`/`tabindex`/teclado;
   input sin `<label for>`; error sin `aria-describedby`; `outline: none` sin sustituto; modal sin
   foco atrapado ni Escape; información solo por color. Bloqueante si impide completar el flujo
   con teclado o lector de pantalla.
6. **Rendimiento** (solo listados o consultas nuevas). N+1 (colección que serializa una relación
   sin `addSelect`); filtro declarado sobre columna sin índice; colección sin paginación;
   búsqueda sin debounce ni cancelación; `v-for` con el índice como `:key` en listas que se
   reordenan. Se detecta contando consultas (Profiler) o midiendo, no adivinando.

## Verificar con comandos cuando el diff toca auth, permisos o datos personales

```bash
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" http://localhost:8000/api/login_check -d '{"username":"user","password":"pass_1234"}' | php -r 'echo json_decode(stream_get_contents(STDIN))->token;')
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/<recurso>/<id-ajeno>    # esperado: 403
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/merge-patch+json" http://localhost:8000/api/users/<id> -d '{"roles":["ROLE_ADMIN"]}'   # no debe cambiar roles
composer audit && npm audit --audit-level=high
```

## Formato de cada hallazgo

```
[BLOQUEANTE] src/Service/Order/OrderCreator.php:41 — con carrito vacío divide por cero al calcular la media — comprobar count() antes y devolver 422 con violation en items
[NOTA] src/views/products/ProductListView.vue:12 — el debounce está inline; ya existe useDebounce en composables/
```

Una línea por hallazgo: severidad, archivo:línea, qué pasa y cuándo, arreglo. Máximo siete
hallazgos: si hay más, los siete peores y una frase con el patrón que se repite.
