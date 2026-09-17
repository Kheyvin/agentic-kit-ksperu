---
id: TASK-XXX
titulo: 
instancia: backend          # carpeta de la instancia sobre la que se trabaja (una sola)
agente: backend-dev         # backend-dev | frontend-dev
estado: pendiente           # pendiente | en_curso | bloqueada | hecha  (se cambia con estado.sh --marcar)
depende_de: []              # [TASK-001]
revision: no                # sí → al terminar pasa por el reviewer (login, permisos, datos personales, dinero, borrado)
---

# TASK-XXX — <título>

## Objetivo
Una frase: qué existe al terminar que no existía antes.

## Contexto
Solo lo que no se deduce del código: decisiones tomadas, restricciones, qué ya existe y se
reutiliza (con su ruta). Quien ejecuta esto no ha visto ninguna conversación. Máximo 15 líneas.

## Contrato
Fragmento literal de `docs/contracts/<instancia>.md` que aplica (endpoints, campos, errores).
Si la tarea añade o cambia endpoints, el agente actualiza el contrato en esta misma tarea.
Si no toca la API: "Sin cambios de contrato".

## Criterios de aceptación
- [ ] AC-1 — observable desde fuera: una petición y su respuesta, o lo que ve el usuario
- [ ] AC-2 —

## Fuera de alcance
- 

## Bitácora
<!-- La escribe el agente al terminar: archivos tocados · decisiones · resultado del gate · pendientes o dudas. -->
