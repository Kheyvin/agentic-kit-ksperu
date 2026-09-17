# <Proyecto>

**Qué es:** una frase, como se lo dirías a quien lo va a usar.
**Tipo:** SPA · ERP · CRM · panel · landing · API pública.
**Para quién:** actores y qué puede hacer cada uno (esto define los roles).

## Instancias

| Instancia | Capa | Consume / la consume | Contrato |
|---|---|---|---|
| `backend` | Symfony 8 + API Platform | la consume `frontend` | `docs/contracts/backend.md` |
| `frontend` | Vue 3 + Vite | consume `backend` | — |

## Alcance

- Hace: 
- No hace (por ahora): 

## Modelo de datos

Una línea por entidad: campos clave, relaciones, qué se borra y qué se archiva.

- 

## Decisiones

Se anexa, nunca se reescribe. Una línea: fecha, qué se decidió, por qué (y qué se descartó).

- AAAA-MM-DD — SQLite en desarrollo, login por `username`, sin refresh token, sin librería de animación (valores por defecto del kit).

## Glosario

- 
