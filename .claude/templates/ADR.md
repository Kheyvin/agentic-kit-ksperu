# ADR-XXX — <decisión en una frase>

- **Estado:** propuesto | aceptado | reemplazado por ADR-YYY
- **Fecha:** 
- **Afecta a:** backend | frontend | contrato | infraestructura

## Contexto

Qué problema obliga a decidir ahora y qué restricciones existen (plazo, equipo de una persona,
stack fijo, volumen esperado). Sin contexto, la decisión no se puede reevaluar después.

## Decisión

Qué se hace. En presente e imperativo: "Los tokens de refresco se persisten en base de datos
con rotación de un solo uso."

## Alternativas descartadas

> Esta sección es el verdadero valor del ADR. Dentro de seis meses, cuando alguien proponga la
> opción B, aquí está por qué ya se dijo que no.

### Alternativa A — <nombre>
Qué era, qué la hacía atractiva, **por qué se descartó**.

### Alternativa B — <nombre>
Ídem.

## Consecuencias

**Positivas**
- 

**Negativas o coste asumido**
- 

**Qué haría falta para revertir esto**
- 

## Cumplimiento

Cómo se verifica que el código sigue esta decisión: un gate, un test, una revisión manual.
Una decisión sin forma de verificarla se erosiona sola en tres semanas.
