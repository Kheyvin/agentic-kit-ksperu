---
name: security-review
description: Revisión de seguridad aplicada a Symfony/API Platform con JWT y a la SPA Vue — autenticación, autorización por Voter, exposición de datos, secretos, CORS y dependencias. Úsalo en cualquier cambio que toque login, permisos, datos personales o configuración de seguridad.
---

# Revisión de seguridad

Checklist OWASP adaptado a este stack. Todo hallazgo aquí es **BLOQUEANTE por defecto**:
la carga de la prueba está en justificar por qué no lo es.

## Autenticación

- [ ] `plainPassword` no mapeado y hasheado en el Processor; nunca persistido en claro.
- [ ] TTL del access corto (3600s). Un access de días anula el modelo entero.
- [ ] Login **excluido** del interceptor de 401: si no, unas credenciales malas cierran la
      sesión en vez de pintar el error en el formulario.
- [ ] Un `401` limpia el token del storage. Dejarlo ahí caducado no es explotable, pero
      esconde el fallo real cuando alguien depura.
- [ ] Mensaje de credenciales inválidas genérico: no revela si el `username` existe.
- [ ] Sin rate limiting → hallazgo MAYOR en login y recuperación de contraseña.

## Autorización

- [ ] Toda operación de API Platform declara `security:` explícitamente. Sin `security` = pública.
- [ ] Permisos sobre objetos con **Voter**, no con `if` en services.
- [ ] `access_control` cierra `^/api` con `IS_AUTHENTICATED_FULLY`; las excepciones son
      explícitas y revisadas.
- [ ] IDOR: pedir el recurso de otro usuario por su IRI devuelve `403`, no `200`.
- [ ] Escalada por payload: enviar `roles` o `owner` en un POST no cambia nada
      (campo fuera del grupo de escritura o forzado en el Processor).

## Exposición de datos

- [ ] Ningún campo sin grupo de serialización. Auditar la entidad entera, no solo lo nuevo.
- [ ] `password`, hashes, tokens y campos internos jamás en un grupo de lectura.
- [ ] El `500` que llega al cliente no lleva traza ni mensaje interno.
- [ ] Relaciones que arrastran datos ajenos por serialización en cascada.

## Inyección y entrada

- [ ] Parámetros bindeados en todo QueryBuilder; cero concatenación.
- [ ] Toda escritura validada con constraints; unicidad con `UniqueEntity` **y** constraint de BD.
- [ ] Subida de archivos: tipo MIME real verificado, tamaño limitado, nombre saneado, guardado
      fuera del directorio público.

## Secretos y configuración

- [ ] `.env.local` y `config/jwt/*.pem` en `.gitignore` y ausentes del historial de git.
- [ ] Cero credenciales en el código. `grep` de `password|secret|api_key` con literal largo.
- [ ] CORS con el origen exacto de cada SPA. Con varios frontends, cada puerto de Vite es un
      origen distinto: se listan todos. `allow_origin: ['*']` es bloqueante.

## Frontend

- [ ] El token persistido es el único; su TTL de una hora es lo que limita el daño si se
      filtra. Nada más de la sesión se guarda en `localStorage`.
- [ ] Sin `v-html` con contenido del servidor sin sanear.
- [ ] Los guards de rol son UX, no seguridad: **cada endpoint valida por su cuenta**.
      Un frontend que oculta un botón sin backend que rechace la llamada es un hallazgo.

## Dependencias

```bash
composer audit
npm audit --audit-level=high
```

## Salida

Escribe los hallazgos en `docs/audits/AUDIT-XXX.md` con severidad, ubicación, vector de ataque
concreto y corrección propuesta. Un hallazgo sin vector explicado ("esto es inseguro") no es
accionable: describe qué haría un atacante, paso a paso.
