# Estándar de animación — GSAP en Vue 3

Adaptación de las skills oficiales de GreenSock (`greensock/gsap-skills`: `gsap-core`,
`gsap-timeline`, `gsap-scrolltrigger`, `gsap-performance`, `gsap-utils`, `gsap-frameworks`)
a la estructura de este kit y al stack Vue 3 + Vite + Pinia + Tailwind.

Documentación oficial: <https://gsap.com/docs/v3/>

---

## 1. Instalación y registro

GSAP **no viene instalado**. Solo entra si el usuario lo pide y queda un ADR que lo justifique
(ver `SKILL.md`, sección "GSAP es opcional y se pide").

```bash
npm install gsap
```

GSAP es gratuito, incluidos ScrollTrigger y el resto de plugins antes de pago, desde que
Webflow lo liberó. No hay licencia que gestionar.

Los plugins se registran **una sola vez**, al cargar el módulo del composable — nunca dentro del
`setup()` de un componente, que se ejecuta en cada montaje:

```js
gsap.registerPlugin(ScrollTrigger)
```

---

## 2. El composable — punto único de entrada

Ningún componente importa `gsap`. La carga es dinámica para no engordar el bundle inicial.

```js
// composables/useGsap.js
let cargado = null

/**
 * Carga GSAP y los plugins pedidos una sola vez por sesión.
 * @param {string[]} plugins  p. ej. ['ScrollTrigger']
 * @returns {Promise<{gsap: import('gsap').GSAP, ScrollTrigger?: any}>}
 */
export function useGsap(plugins = []) {
  cargado ??= (async () => {
    const { gsap } = await import('gsap')
    const registrados = {}

    if (plugins.includes('ScrollTrigger')) {
      const { ScrollTrigger } = await import('gsap/ScrollTrigger')
      gsap.registerPlugin(ScrollTrigger)
      registrados.ScrollTrigger = ScrollTrigger
    }

    gsap.defaults({ duration: 0.6, ease: 'power2.out' })
    return { gsap, ...registrados }
  })()

  return cargado
}
```

`gsap.defaults()` fija el criterio del proyecto en un solo sitio: si mañana todas las
animaciones deben ser más rápidas, se cambia aquí y no en cuarenta tweens.

### Composable de animación reutilizable

Una animación que se usa en dos sitios es un composable, igual que cualquier otra lógica
repetida (§8 del estándar frontend).

```js
// composables/useRevealOnScroll.js
import { onMounted, onUnmounted } from 'vue'
import { useGsap } from './useGsap'

/**
 * Revela los hijos que coincidan con `selector` al entrar en pantalla.
 * @param {import('vue').Ref<HTMLElement|null>} scope  contenedor raíz
 * @param {string} selector
 */
export function useRevealOnScroll(scope, selector = '[data-reveal]') {
  let ctx, mm

  onMounted(async () => {
    if (!scope.value) return
    const { gsap } = await useGsap(['ScrollTrigger'])

    mm = gsap.matchMedia()
    mm.add({ reduce: '(prefers-reduced-motion: reduce)' }, (self) => {
      const { reduce } = self.conditions
      ctx = gsap.context(() => {
        gsap.from(selector, {
          autoAlpha: 0,
          y: reduce ? 0 : 24,
          duration: reduce ? 0 : 0.6,
          stagger: 0.08,
          scrollTrigger: { trigger: scope.value, start: 'top 80%' },
        })
      }, scope.value)
      return () => ctx?.revert()
    }, scope.value)
  })

  onUnmounted(() => { mm?.revert(); ctx = null })
}
```

Uso desde la vista:

```vue
<script setup>
import { ref } from 'vue'
import { useRevealOnScroll } from '@/composables/useRevealOnScroll'

const contenedor = ref(null)
useRevealOnScroll(contenedor)
</script>

<template>
  <section ref="contenedor">
    <article v-for="p in productos" :key="p.id" data-reveal>{{ p.name }}</article>
  </section>
</template>
```

---

## 3. Ciclo de vida en Vue — la fuente de los bugs

| Momento | Qué toca |
|---|---|
| `setup()` | **Nada de animación.** El DOM no existe todavía |
| `onMounted` | Crear el contexto y las animaciones |
| `onUnmounted` | `ctx.revert()` / `mm.revert()` |

`gsap.context(fn, scope)` hace dos cosas a la vez, y las dos importan:

1. **Registra** todo lo creado dentro para poder revertirlo de golpe.
2. **Acota los selectores** al elemento `scope`. Sin él, `'.card'` alcanza las tarjetas de otras
   vistas montadas a la vez y animas cosas que no son tuyas.

`ctx.revert()` no solo mata los tweens: **devuelve los estilos inline al estado previo**. Por eso
es preferible a `ctx.kill()`, que los deja congelados en el último frame.

Si usas `matchMedia`, él ya crea su contexto interno: **no lo anides** con `gsap.context()`.
Limpia con `mm.revert()`.

### Con `v-if`, listas y datos asíncronos

Los elementos que aparecen después necesitan `await nextTick()` antes de animarlos, y
ScrollTrigger necesita recalcular posiciones cuando cambia la altura de la página:

```js
watch(() => items.value.length, async () => {
  await nextTick()
  ScrollTrigger.refresh()
})
```

### Con Vue Router

Al cambiar de ruta, los ScrollTriggers de la vista anterior deben morir. Si cada vista limpia su
propio contexto en `onUnmounted`, ya está resuelto. El fallo típico es crear ScrollTriggers en
un layout persistente que no se desmonta nunca: ahí hay que matarlos a mano en el guard.

---

## 4. Core — tweens

- `gsap.to(targets, vars)` — del estado actual a `vars`. El más común.
- `gsap.from(targets, vars)` — de `vars` al estado actual. Ideal para entradas.
- `gsap.fromTo(targets, from, to)` — inicio y fin explícitos; no lee el estado actual.
- `gsap.set(targets, vars)` — aplica ya, sin duración.

Propiedades en **camelCase** (`backgroundColor`, `rotationX`).

### `vars` habituales

| Clave | Qué hace |
|---|---|
| `duration` | Segundos (por defecto 0.5) |
| `delay` | Espera antes de arrancar |
| `ease` | `"power2.out"`, `"back.out(1.7)"`, `"elastic.out(1, 0.3)"`, `"none"` |
| `stagger` | `0.1`, o `{ amount: 0.3, from: 'center' }`, `{ each: 0.1, from: 'random' }` |
| `repeat` | Número, o `-1` para infinito |
| `yoyo` | Con `repeat`, alterna la dirección |
| `overwrite` | `false` (defecto), `true`, o `"auto"` (mata solo las props solapadas) |
| `onStart` / `onUpdate` / `onComplete` | Callbacks |
| `immediateRender` | `true` por defecto en `from()`/`fromTo()` |

**`immediateRender` es la trampa clásica:** si dos `from()` tocan la misma propiedad del mismo
elemento, el segundo aplica su estado inicial nada más crearse y pisa el resultado del primero.
En el segundo y siguientes, `immediateRender: false`.

### Transformaciones

Usa los alias de GSAP, no la cadena `transform`: se aplican en orden consistente y son más
rápidos.

| GSAP | Equivale a |
|---|---|
| `x`, `y`, `z` | `translateX/Y/Z` (px por defecto) |
| `xPercent`, `yPercent` | Translación en %; funcionan en SVG |
| `scale`, `scaleX`, `scaleY` | `scale` |
| `rotation` | `rotate` (grados; o `"1.25rad"`) |
| `rotationX`, `rotationY` | Rotación 3D |
| `skewX`, `skewY` | `skew` |
| `transformOrigin` | `transform-origin` |

- **`autoAlpha` en vez de `opacity`**: en 0 pone además `visibility: hidden`, así el elemento
  invisible no sigue capturando clics. Es el bug de "hay un botón fantasma encima".
- **Valores relativos**: `x: '+=20'`, `rotation: '-=30'`, `'*=2'`, `'/=2'`.
- **Rotación direccional**: sufijos `_short`, `_cw`, `_ccw` — `rotation: '-170_short'` gira 20°
  en lugar de 340°.
- **Variables CSS**: `{ '--hue': 180 }` se anima.
- **`svgOrigin`** (solo SVG) usa coordenadas globales del SVG. `svgOrigin` y `transformOrigin`
  son excluyentes.
- **`clearProps`**: quita estilos inline al terminar, para que vuelva a mandar el CSS. Limpiar
  cualquier propiedad de transformación limpia la transformación entera.

### Valores por función

Se evalúa una vez por target:

```js
gsap.to('.item', { x: (i) => i * 50, stagger: 0.1 })
```

### Easing

```
"none"
"power1".."power4"   + .in / .out / .inOut
"back"  "bounce"  "circ"  "elastic"  "expo"  "sine"
```

Curvas propias solo con `CustomEase`, y solo si ninguna de las anteriores sirve.

---

## 5. Timeline — secuenciar

Encadenar con `delay` es frágil: cambiar una duración obliga a recalcular todas las demás a mano.

```js
const tl = gsap.timeline({ defaults: { duration: 0.5, ease: 'power2.out' } })
tl.to('.a', { x: 100 })
  .to('.b', { y: 50 })
  .to('.c', { autoAlpha: 0 })
```

### Parámetro de posición (tercer argumento)

| Valor | Significado |
|---|---|
| `1` | En el segundo 1 |
| `"+=0.5"` | 0.5 s después de que acabe lo anterior |
| `"-=0.2"` | Solapa 0.2 s con lo anterior |
| `"<"` | Arranca a la vez que lo anterior |
| `">"` | Después de lo anterior (por defecto) |
| `"<0.2"` | 0.2 s después del **inicio** de lo anterior |
| `"etiqueta+=0.3"` | Relativo a una etiqueta |

### Etiquetas y anidado

```js
tl.addLabel('intro', 0)
tl.to('.a', { x: 100 }, 'intro')
tl.tweenFromTo('intro', 'outro')

const master = gsap.timeline()
master.add(hijo, 0).to('.c', { autoAlpha: 0 }, '+=0.2')
```

Control: `.play()`, `.pause()`, `.reverse()`, `.restart()`, `.time(2)`, `.progress(0.5)`,
`.kill()`.

---

## 6. ScrollTrigger

```js
gsap.registerPlugin(ScrollTrigger)

gsap.to('.box', {
  x: 500,
  scrollTrigger: {
    trigger: '.box',
    start: 'top center',
    end: 'bottom center',
    scrub: true,
  },
})
```

### Opciones que se usan de verdad

| Opción | Qué hace |
|---|---|
| `trigger` | Elemento que define el inicio (obligatorio) |
| `start` / `end` | `"top bottom"` por defecto / `"bottom top"`. También `"+=1000"` |
| `scrub` | Liga el progreso al scroll. `true` directo, número = segundos de suavizado |
| `toggleActions` | Cuatro acciones: `onEnter onLeave onEnterBack onLeaveBack` |
| `pin` | Fija el elemento mientras está activo |
| `pinSpacing` | `true` por defecto; evita que el layout colapse |
| `markers` | Marcas visuales de depuración. **Nunca en código commiteado** |
| `once` | Se destruye tras la primera pasada |
| `scroller` | Contenedor de scroll, si no es el viewport |
| `refreshPriority` | Orden de recálculo si no se crean de arriba abajo |
| `containerAnimation` | Liga el scroll vertical a una animación horizontal |
| `snap` | Ajusta a valores de progreso o a etiquetas |

**`scrub` y `toggleActions` son excluyentes.** Con los dos, manda `scrub` y el otro se ignora en
silencio — es una fuente clásica de "no hace lo que le pido".

### Patrones

```js
// Timeline pineado
const tl = gsap.timeline({
  scrollTrigger: { trigger: '.container', start: 'top top', end: '+=2000', scrub: 1, pin: true },
})
tl.to('.a', { x: 100 }).to('.b', { y: 50 })

// Lotes: un ScrollTrigger por elemento, callbacks agrupados
ScrollTrigger.batch('.card', {
  start: 'top 85%',
  onEnter: (lote) => gsap.to(lote, { autoAlpha: 1, y: 0, stagger: 0.1, overwrite: true }),
  onLeaveBack: (lote) => gsap.set(lote, { autoAlpha: 0, y: 50, overwrite: true }),
})

// Scroll horizontal falso: la animación horizontal SIEMPRE con ease: 'none'
const tween = gsap.to(el, {
  xPercent: () => Math.max(0, window.innerWidth - el.offsetWidth),
  ease: 'none',
  scrollTrigger: { trigger: el, pin: el.parentNode, start: 'top top', end: '+=1000' },
})
gsap.to('.anidado', {
  y: 100,
  scrollTrigger: { containerAnimation: tween, trigger: '.wrapper', start: 'left center' },
})
```

### Refresco y limpieza

```js
ScrollTrigger.refresh()                              // tras cambios de layout
ScrollTrigger.getAll().forEach((t) => t.kill())      // barrido de emergencia
ScrollTrigger.getById('mi-id')?.kill()
```

El viewport dispara `refresh()` solo al redimensionar (con 200 ms de rebote). Lo que **no**
detecta es que hayas cargado datos, abierto un acordeón o terminado de cargar fuentes e
imágenes: eso lo llamas tú.

---

## 7. Rendimiento

El presupuesto del kit son 200 KB gzip de bundle inicial. GSAP con ScrollTrigger no cabe si se
importa estáticamente: por eso `useGsap.js` usa `import()` dinámico.

- Anima **transformaciones y opacidad**: se resuelven en el compositor, sin layout ni repintado.
  `width`, `height`, `top` y `left` fuerzan reflow en cada frame.
- `will-change: transform` **solo** en el elemento que se anima y mientras se anima. Ponerlo
  "por si acaso" en todo crea capas de más y empeora lo que pretendía arreglar.
- `stagger` en vez de N tweens con `delay` distinto.
- `gsap.quickTo()` para valores que cambian muchas veces por segundo (seguidor de ratón):

  ```js
  const xTo = gsap.quickTo('#cursor', 'x', { duration: 0.4, ease: 'power3' })
  const yTo = gsap.quickTo('#cursor', 'y', { duration: 0.4, ease: 'power3' })
  addEventListener('mousemove', (e) => { xTo(e.pageX); yTo(e.pageY) })
  ```

- Pausa o destruye lo que está fuera de pantalla.
- Limpia siempre: tweens y triggers huérfanos siguen consumiendo cada frame.

---

## 8. Utilidades

```js
gsap.utils.clamp(0, 100, valor)
gsap.utils.mapRange(0, 500, 0, 1, scrollY)
gsap.utils.interpolate('#f00', '#00f', 0.5)
gsap.utils.random(-100, 100, 1)
gsap.utils.snap(10, valor)
gsap.utils.wrap(['a', 'b', 'c'], indice)
gsap.utils.toArray('.item')          // NodeList → array de verdad
```

`gsap.utils.toArray()` evita el error de tratar una `NodeList` como array.

---

## 9. Accesibilidad

`prefers-reduced-motion` es un criterio de la skill `a11y` y aquí se cumple con `matchMedia`:

```js
const mm = gsap.matchMedia()
mm.add(
  {
    esEscritorio: '(min-width: 800px)',
    reduce: '(prefers-reduced-motion: reduce)',
  },
  (self) => {
    const { esEscritorio, reduce } = self.conditions
    gsap.to('.box', {
      rotation: esEscritorio ? 360 : 180,
      duration: reduce ? 0 : 2,
    })
    return () => { /* limpieza propia si hace falta */ }
  },
)
onUnmounted(() => mm.revert())
```

Cuando una condición deja de cumplirse, GSAP revierte solo lo creado en ese bloque. Es también
la forma correcta de tener animaciones distintas en móvil y escritorio sin duplicar código.

Además:

- La animación **no puede ser el único portador de significado**. Si algo aparece animado, debe
  ser igual de comprensible sin movimiento.
- Nada de animaciones infinitas y llamativas en contenido que se lee.
- El foco de teclado no se pierde por culpa de un elemento animado o pineado.

---

## 10. Checklist de aceptación

- [ ] GSAP está instalado porque se pidió, y hay un ADR que lo justifica.
- [ ] Ningún componente importa `gsap`; todo pasa por `composables/`.
- [ ] La carga es dinámica y el bundle inicial sigue bajo presupuesto.
- [ ] `gsap.registerPlugin()` se ejecuta una vez, no en cada montaje.
- [ ] Toda animación se crea en `onMounted` y se revierte en `onUnmounted`.
- [ ] `gsap.context()` siempre con scope; `matchMedia` sin contexto anidado.
- [ ] Entrar y salir de la vista cinco veces no aumenta `ScrollTrigger.getAll().length`.
- [ ] Solo se animan transformaciones y opacidad; nada de `width`/`height`/`top`/`left`.
- [ ] Secuencias con timeline, no con `delay` encadenado.
- [ ] ScrollTrigger en el timeline o tween de primer nivel, nunca en un hijo.
- [ ] `scrub` y `toggleActions` no conviven en el mismo ScrollTrigger.
- [ ] `ScrollTrigger.refresh()` tras cargar datos o cambiar el layout.
- [ ] `prefers-reduced-motion` respetado y probado con la preferencia activa.
- [ ] Cero `markers: true` en el código commiteado.
