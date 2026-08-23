---
description: El arquitecto te entrevista y cierra el alcance antes de que nadie escriba código
argument-hint: "[descripción breve de lo que quieres construir]"
---

Invoca al subagente `architect` para hacer discovery.

Contexto inicial del usuario: $ARGUMENTS

El arquitecto debe:

1. Entrevistar **por bloques de 3 preguntas**, esperando respuesta entre bloques. No volcar
   veinte preguntas de golpe.
2. Repreguntar con opciones concretas cuando una respuesta sea vaga.
3. Producir `docs/BRIEF.md`, `docs/CONTRACT.md`, el modelo de datos y los ADR iniciales.
4. Devolver un resumen de una página y **pedir confirmación explícita** al usuario.

Hasta que el usuario confirme, no se planifica ni se codifica nada. Al confirmar, propón `/plan`.
