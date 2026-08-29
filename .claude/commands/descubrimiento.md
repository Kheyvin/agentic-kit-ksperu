---
description: El arquitecto te entrevista y cierra el alcance antes de que nadie escriba código
argument-hint: "[descripción breve de lo que quieres construir]"
---

Invoca al subagente `architect` para hacer discovery.

Contexto inicial del usuario: $ARGUMENTS

El arquitecto debe:

1. Entrevistar **sin límite de preguntas ni de rondas**, hasta que pueda describir el sistema sin
   usar la palabra "depende". Agrupa por tema —no por cuota— en bloques que quepan en una sola
   respuesta cómoda, y espera contestación antes de seguir. Volcar cuarenta preguntas de golpe
   agota; racionar de tres en tres cuando el tema pide diez es igual de malo.
2. Repreguntar con opciones concretas cuando una respuesta sea vaga, y volver atrás sin problema
   si algo que se responde tarde invalida una decisión anterior.
3. Cerrar **qué tipo de aplicación es** (SPA, ERP, CRM, panel, landing, API pública…) y **la
   forma del proyecto**: cuántos backends, cuántos frontends, cómo se llama cada uno y quién
   consume a quién.
4. Producir `docs/BRIEF.md`, un `docs/contracts/<instancia>.md` por backend, el modelo de datos
   y los ADR iniciales.
5. Devolver un resumen de una página y **pedir confirmación explícita** al usuario.

No preguntes por despliegue, CI, servidores ni Docker: no existen en este kit.

Hasta que el usuario confirme, no se planifica ni se codifica nada. Al confirmar, propón
`/planificar`.
