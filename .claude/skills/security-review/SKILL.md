---
name: security-review
description: Revisión de seguridad aplicada a Symfony/API Platform con JWT y a la SPA Vue — autenticación, autorización por Voter, exposición de datos, secretos, CORS y dependencias. Úsalo en cualquier cambio que toque login, permisos, datos personales o configuración de seguridad.
---

# Revisión de seguridad

Checklist OWASP adaptado a este stack. Todo hallazgo aquí es **BLOQUEANTE por defecto**:
la carga de la prueba está en justificar por qué no lo es.

## Autenticación

- [ ] `plainPassword` no mapeado y hasheado en el Processor; nunca persistido en claro.
- [ ] Refresh rotativo con `single_use: true`; el anterior queda invalidado.
- [ ] Logout revoca el refresh token en BD. Sin eso, "cerrar sesión" es decorativo.
- [ ] TTL del access corto (3600s). Un access de días anula el modelo entero.
- [ ] Login y refresh **excluidos** del interceptor de 401 (si no, bucle infinito).
- [ ] Mensaje de credenciales inválidas genérico: no revela si el email existe.
- [ ] Sin rate limiting → hallazgo MAYOR en login y recuperación de contraseña.

## Autorización

- [ ] Toda operación de API Platform declara `security:` explícitamente. Sin `security` = pública.
- [ ] Permisos sobre objetos con **Voter**, no con `if` en services.
- [ ] `access_control` cierra `^/api` con `IS_AUTHENTICATED_FULLY`; las excepciones son
      explícitas y revisadas (`/api/docs` en producción: decidir y documentar).
- [ ] IDOR: pedir el recurso de otro usuario por su IRI devuelve `403`, no `200`.
- [ ] Escalada por payload: enviar `roles` o `owner` en un POST no cambia nada
      (campo fuera del grupo de escritura o forzado en el Processor).

## Exposición de datos

- [ ] Ningún campo sin grupo de serialización. Auditar la entidad entera, no solo lo nuevo.
- [ ] `password`, hashes, tokens y campos internos jamás en un grupo de lectura.
- [ ] En producción, `500` sin traza ni mensaje interno; `/api/docs` según decisión.
- [ ] Relaciones que arrastran datos ajenos por serialización en cascada.

## Inyección y entrada

- [ ] Parámetros bindeados en todo QueryBuilder; cero concatenación.
- [ ] Toda escritura validada con constraints; unicidad con `UniqueEntity` **y** constraint de BD.
- [ ] Subida de archivos: tipo MIME real verificado, tamaño limitado, nombre saneado, guardado
      fuera del directorio público.

## Secretos y configuración

- [ ] `.env.local` y `config/jwt/*.pem` en `.gitignore` y ausentes del historial de git.
- [ ] Cero credenciales en el código. `grep` de `password|secret|api_key` con literal largo.
- [ ] CORS con origen exacto de la SPA. `allow_origin: ['*']` en producción es bloqueante.

## Frontend

- [ ] `accessToken` en memoria; solo el refresh persiste. Nunca ambos en `localStorage`.
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
