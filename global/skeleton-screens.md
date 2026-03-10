# skeleton-screens.md — Skeleton Screen Pattern

Machine-optimized. Claude-facing only.

---

## When to use

Page loads async data and currently shows a spinner or nothing. Replace with a skeleton component that mirrors the real layout.

---

## Process — always do this before writing

Use the agent-browser skill — do not estimate dimensions from code alone.

1. `agent-browser open <url>` + `agent-browser wait --load networkidle` + `agent-browser screenshot` → see the real loaded layout
2. For each card/element to skeleton: `agent-browser eval 'JSON.stringify(document.querySelector("<selector>").getBoundingClientRect())'` → get exact px height
3. Convert px to rem (divide by 16), apply as `min-height` + `max-height` on skeleton card
4. Match skeleton dimensions exactly so nothing jumps on load

---

## Conventions

- Component: `[feature]-skeleton.component.ts` — inline template (no separate .html), own .scss
- Class naming: `.skeleton-card` for card shells, `.bone` for placeholder elements within
- BEM modifiers on bones: `bone--title`, `bone--subtitle`, `bone--meter` etc.
- Use `:host { display: grid; ... }` when skeleton must participate in a parent grid
- Use `min-height` + `max-height` to lock skeleton card to exact real card height
- Shimmer: single `@keyframes shimmer` in component scss, applied via `::after` with `overflow: hidden` on parent

---

## Loading state pattern

```html
@if (response.pending) {
  <ntm-[feature]-skeleton />
} @else if (response.success) {
  <!-- real content -->
}
```

---

## Shimmer SCSS (copy this)

```scss
@keyframes shimmer {
  from { transform: translateX(-100%); }
  to { transform: translateX(100%); }
}

.bone {
  position: relative;
  overflow: hidden;
  background-color: $grey-5;
  border-radius: 0.25rem;

  &::after {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.6), transparent);
    animation: shimmer 1.5s infinite;
  }
}
```
