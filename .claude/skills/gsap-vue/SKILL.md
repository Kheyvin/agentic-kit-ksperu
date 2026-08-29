---
name: gsap-vue
description: Animación con GSAP en la SPA Vue 3 — instalación opcional, composable con gsap.context y limpieza en onUnmounted, timelines, ScrollTrigger, matchMedia y prefers-reduced-motion. Úsalo cuando el usuario pida animación, scroll-linked, transiciones complejas o una landing, y al revisar cualquier archivo que importe gsap.
---

# GSAP en Vue 3

Adaptado de las skills oficiales de GreenSock (`greensock/gsap-skills`) a la estructura y las
reglas de este kit. El estándar completo está en `reference/gsap-standard.md`; **léelo entero
antes de la primera tarea de animación de una sesión**. Esto es el resumen operativo.

## GSAP es opcional y se pide

**Por defecto GSAP no está instalado.** Las transiciones de Tailwind (`transition`, `duration-*`)
y `<Transition>` de Vue cubren hover, apertura de modales, entradas de lista y cambios de estado.
Esos son el 90% de los casos y no cuestan un kilobyte.

GSAP entra cuando hay una razón que Tailwind no cubre:

- Secuenciar varios pasos con control fino del solape → **timeline**.
- Animación ligada al scroll, pinning, parallax → **ScrollTrigger**.
- Control en runtime: pausar, invertir, buscar una posición, interrumpir.
- Morphing de SVG o coordinación entre muchos elementos.

En un ERP, un CRM o un panel de gestión, la respuesta correcta casi siempre es "no hace falta":
la animación de más ralentiza la navegación que alguien hace cincuenta veces al día. En una
landing o un portfolio, sí.

Si decides que entra, **regístralo en un ADR** con el motivo. No se instala "por si acaso".

```bash
npm install gsap
```

## La regla que más se incumple: limpieza

Un componente Vue se monta y se desmonta muchas veces. Una animación creada al montar y no
destruida al desmontar sigue viva sobre nodos que ya no existen. Se acumulan, y el síntoma
aparece tres pantallas después en forma de scroll que salta o de memoria que crece.

**Todo lo que se crea dentro de `gsap.context()` se revierte con `ctx.revert()`.** Sin excepción.

```js
onMounted(() => {
  ctx = gsap.context(() => { /* tweens y ScrollTriggers */ }, contenedor.value)
})
onUnmounted(() => ctx?.revert())
```

El segundo argumento de `gsap.context()` es el **scope**: los selectores de dentro solo ven
elementos bajo ese elemento raíz. Sin scope, un `.card` de una vista anima las `.card` de otra.

## Dónde vive el código

GSAP es una dependencia de red-adyacente: igual que ningún componente importa `axios`,
**ningún componente importa `gsap` directamente**.

```
composables/
├── useGsap.js          # carga perezosa de gsap y registro de plugins
└── useRevealOnScroll.js # una animación reutilizable = un composable
```

El componente consume el composable y no sabe qué librería hay debajo. Eso mantiene la
animación fuera de la capa de presentación y hace que quitarla luego sea un cambio de un archivo.

`useGsap.js` importa GSAP **dinámicamente** para que no entre en el bundle inicial: el
presupuesto del kit es 200 KB gzip y GSAP con ScrollTrigger se lleva un buen trozo.

## Accesibilidad: `prefers-reduced-motion` no es opcional

Hay personas para las que el movimiento en pantalla provoca mareo. Respetar su preferencia del
sistema es un criterio de la skill `a11y`, y en GSAP se resuelve con `matchMedia`:

```js
const mm = gsap.matchMedia()
mm.add({ reduce: '(prefers-reduced-motion: reduce)' }, (ctx) => {
  const { reduce } = ctx.conditions
  gsap.to('.box', { x: 100, duration: reduce ? 0 : 0.6 })
})
onUnmounted(() => mm.revert())
```

`matchMedia` ya crea su propio contexto: **no anides `gsap.context()` dentro**. Limpia con
`mm.revert()` y nada más.

## Reglas de oro

1. GSAP solo si se pidió y hay ADR. Por defecto, Tailwind y `<Transition>`.
2. **Ningún componente importa `gsap`.** Todo pasa por `composables/`.
3. Import dinámico: GSAP no entra en el bundle inicial.
4. Animaciones creadas en `onMounted`, nunca antes: los selectores necesitan DOM.
5. `gsap.context(fn, scope)` siempre con scope, y `ctx.revert()` en `onUnmounted`.
6. Anima `x`, `y`, `scale`, `rotation` y `autoAlpha`. Nunca `width`, `height`, `top` ni `left`.
7. Secuencias con **timeline**, jamás encadenando `delay`.
8. `gsap.registerPlugin()` una sola vez, al cargar el módulo — no en cada montaje.
9. ScrollTrigger va en el timeline o en el tween de primer nivel, **nunca en un tween hijo**.
10. `prefers-reduced-motion` respetado con `matchMedia`.
11. `markers: true` es de depuración: **nunca se commitea**.

## Antes de cerrar una tarea con animación

```bash
bash .claude/scripts/gate-frontend.sh
```

El gate comprueba que no queden `markers: true` y que nadie importe `gsap` fuera de
`composables/`. Lo que no ve, verifícalo a mano:

- Entra y sal de la vista cinco veces: el número de ScrollTriggers no debe crecer
  (`ScrollTrigger.getAll().length` en la consola).
- Con `prefers-reduced-motion` activo en el sistema, la pantalla es usable y no se mueve.
- Tras cargar datos que cambian la altura de la página, se llamó a `ScrollTrigger.refresh()`.
- El peso del bundle inicial no subió: `npm run build` y compara.
