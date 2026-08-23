---
name: a11y
description: Auditoría de accesibilidad WCAG 2.1 AA sobre componentes Vue y mockups HTML — contraste, foco, teclado, semántica y ARIA. Úsalo al revisar cualquier interfaz, aprobar un mockup o cerrar una tarea de frontend.
---

# Accesibilidad — WCAG 2.1 AA

Se revisa en el **mockup**, no al final. Un problema de accesibilidad detectado en el HTML
estático cuesta un ajuste de markup; detectado en producción cuesta rediseñar el componente.

## Checklist

**Semántica**
- [ ] Un solo `<h1>` por vista; jerarquía de encabezados sin saltos.
- [ ] Landmarks: `<nav>`, `<main>`, `<aside>`, `<header>`. Un `<div>` con `role="navigation"`
      es una señal de que faltaba el elemento correcto.
- [ ] Tablas de datos con `<th scope>` y `<caption>` o `aria-label`.
- [ ] Listas reales para contenido en lista.

**Teclado**
- [ ] Todo lo accionable se alcanza con Tab, en orden lógico visual.
- [ ] `focus-visible` visible en **todos** los interactivos (el estándar Tailwind ya lo exige).
- [ ] Modal: foco atrapado dentro, Escape cierra, al cerrar el foco vuelve al disparador.
- [ ] Cero `tabindex` positivos. Cero `outline: none` sin sustituto.
- [ ] Un `div` con `@click` sin `role`, `tabindex` ni handler de teclado es un bloqueante.

**Formularios**
- [ ] Cada input con `<label for>` asociado. El placeholder no es una etiqueta.
- [ ] Error asociado con `aria-describedby` y `aria-invalid` — así el mapeo de `violations`
      del backend llega también al lector de pantalla.
- [ ] Campos requeridos marcados en el markup, no solo con un asterisco de color.

**Color y contraste**
- [ ] Texto normal ≥ 4.5:1; texto grande y componentes de UI ≥ 3:1.
- [ ] El color nunca es el único portador de información: los badges de estado llevan texto
      o icono además del color.
- [ ] Verifica los tokens de `@theme` una vez, no cada clase: si el token pasa, todo su uso pasa.

**Dinámica**
- [ ] Estados de carga anunciados (`aria-busy` o `role="status"`).
- [ ] Toasts en `aria-live="polite"`; errores críticos en `assertive`.
- [ ] `prefers-reduced-motion` respetado (obligatorio si hay GSAP en una landing).
- [ ] Imágenes con `alt` descriptivo; las decorativas con `alt=""`.

**Táctil**
- [ ] Objetivos ≥ 44×44 px con separación suficiente.

## Verificación automática

```bash
npm install -D @axe-core/playwright
```

```js
import AxeBuilder from '@axe-core/playwright'
const { violations } = await new AxeBuilder({ page })
  .withTags(['wcag2a', 'wcag2aa']).analyze()
expect(violations).toEqual([])
```

axe detecta aproximadamente un tercio de los problemas reales. El resto —orden de foco,
sentido del `alt`, claridad del mensaje de error— exige revisión manual. Verde en axe no es
"accesible", es "sin errores automáticos".
