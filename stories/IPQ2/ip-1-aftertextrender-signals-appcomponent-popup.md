# chore(ip-sprint): IP-1 Replace setTimeout + cdr.detectChanges with afterNextRender and signals

**Sprint:** IP Q2 2026
**Branch:** `chore/ip-sprint/ip-1-aftertextrender-signals-appcomponent-popup`
**Project:** NTM (`ntm-frontend`)
**Date:** 2026-03-02
**Difficulty:** Easy
**Estimated days:** 1

---

## Learning Objective

Learn two things in one tight, bounded change:

1. **`afterNextRender()`** — Angular 17's correct replacement for `setTimeout(() => {}, 0)` patterns that exist only to defer execution until after the DOM has been updated. Understand why `setTimeout` is fragile (it races against the Angular rendering cycle) and why `afterNextRender` is semantically correct (it fires exactly once, after Angular has completed the next render, with guaranteed DOM availability).

2. **`signal<boolean>()` for simple UI state** — Replacing plain class property mutations + `cdr.detectChanges()` calls with `signal()`. Understand why signals make `ChangeDetectorRef` unnecessary: when a signal changes, Angular automatically schedules the minimal re-render needed. No manual triggering, no lifecycle hook juggling.

This story teaches the **core mental shift from imperative to reactive change management**. It is deliberately scoped small so the new concepts are visible in isolation before being applied to more complex scenarios in later stories.

---

## Learning Context

### Why this pattern exists in the codebase

NTM was originally built against Angular's default change detection model. When a component has no `OnPush` strategy and relies on Zone.js to trigger rendering, manually calling `cdr.detectChanges()` is a workaround for cases where Angular's automatic detection doesn't fire at the right moment — typically after async operations or when the developer isn't sure whether a change will be picked up.

`setTimeout(() => {}, 0)` (a "zero-delay timeout") is a classic JavaScript trick to defer work to the next event loop tick, which in the Angular Zone.js context usually means "after the current rendering cycle." Developers use it when they need to wait for DOM elements to exist or for Angular to finish rendering before manipulating something. It works, but it's fragile: the actual timing depends on the browser's event queue, not on Angular's rendering schedule.

`afterNextRender()` was introduced in Angular 17 specifically to replace this pattern. It runs exactly once after the next full DOM update, inside Angular's rendering pipeline, not outside it in the JavaScript event loop.

### What exists in the NTM codebase today

**`AppComponent`** (`ntm-frontend/src/app/app.component.ts`):
- Implements `AfterViewInit`
- Injects `ChangeDetectorRef`
- In `ngAfterViewInit()`:
  - Sets `showWelcomePopup = true` or `false` based on a visit service
  - Uses `setTimeout(() => { this.showDoMoreBanner = ...; this.#cdr.detectChanges(); }, 4000)` to show a banner 4 seconds after load
  - Calls `this.#cdr.detectChanges()` manually at the end of `ngAfterViewInit`
- `showWelcomePopup` and `showDoMoreBanner` are plain boolean class properties (not signals)

**`PopupComponent`** (`ntm-frontend/src/app/shared/components/popup/popup.component.ts`):
- Has an `openPopup()` method that uses `setTimeout(() => { this.visibleClass = 'is-visible'; this.#cdr.detectChanges(); }, 0)` to add the CSS class that triggers the popup's enter animation
- Has a `closePopup()` method that uses `setTimeout(() => { this.visible = false; }, 300)` — this 300ms is intentional (waits for the CSS close animation to complete before removing from DOM), so this one stays
- Calls `cdr.detectChanges()` in multiple places

### Why this is wrong and how to fix it

The `setTimeout(..., 0)` in `PopupComponent.openPopup()` exists to ensure the `is-visible` class is added after the popup element has been inserted into the DOM. This is exactly what `afterNextRender()` is for. With `afterNextRender()`, Angular guarantees the callback runs after the DOM is updated — no guessing, no race condition.

The `cdr.detectChanges()` calls in both components exist because plain boolean properties don't notify Angular of changes when used with manual timing. Once these properties become `signal<boolean>()`, Angular's signal-based change tracking picks up the changes automatically — `cdr.detectChanges()` becomes completely unnecessary.

Note: `afterNextRender()` must be called in an injection context (constructor or field initializer). It cannot be called inside `ngAfterViewInit` or inside `openPopup()` directly. For the popup use case, you set up the `afterNextRender` callback inside the constructor to run after the component first renders, or you use `afterNextRender` with a trigger mechanism.

Actually, the right pattern for `openPopup()` is slightly different: since the popup is shown/hidden reactively, you should use `afterNextRender` in the constructor with a condition, OR simply rely on the signal change causing a re-render and then using `effect()` to run post-render side effects. Explore both approaches and choose the cleaner one.

---

## Analysis

### Files to change

| File | Current issue | Fix |
|------|--------------|-----|
| `ntm-frontend/src/app/app.component.ts` | `AfterViewInit`, `ChangeDetectorRef`, `setTimeout`, plain boolean props | `afterNextRender`, `signal<boolean>()`, remove `cdr` |
| `ntm-frontend/src/app/shared/components/popup/popup.component.ts` | `setTimeout(..., 0)` + `cdr.detectChanges()` in `openPopup()` | `afterNextRender` for the open animation; keep `setTimeout(300)` for close animation |

### What NOT to change

- The 300ms `setTimeout` in `PopupComponent.closePopup()` — this is intentional and correct, it waits for the CSS transition to finish before hiding the element
- The `VisitService` logic — we're only changing how AppComponent reacts to it, not the service itself
- The 4-second delay for the do-more banner — the `setTimeout(4000)` timer stays, only the `cdr.detectChanges()` inside it is removed (signals make it unnecessary)

### Key concepts to research before starting

- `afterNextRender()` docs and examples — note it only runs in browser context (not during SSR)
- `signal<T>()`, `.set()`, `.update()` — basic signal API
- Why `ChangeDetectorRef.detectChanges()` is unnecessary when using signals with `OnPush` or signal-tracked components
- Angular lifecycle hook ordering: `ngOnInit` → `ngAfterViewInit` → render → `afterNextRender`

### Acceptance criteria

- `AppComponent` no longer implements `AfterViewInit`
- `ChangeDetectorRef` is no longer injected in `AppComponent`
- `showWelcomePopup` and `showDoMoreBanner` are `signal<boolean>(false)`
- The 4-second banner delay still works correctly (use `afterNextRender` + `setTimeout(4000)` combination, or research the cleanest approach)
- All `cdr.detectChanges()` calls removed from `AppComponent`
- `PopupComponent`: the `setTimeout(..., 0)` in `openPopup()` is replaced with `afterNextRender()`
- `PopupComponent`: the `setTimeout(300)` in `closePopup()` remains unchanged
- Build passes, popup animation works, welcome popup and do-more banner appear at the correct times

---

## Implementation Plan

### Phase 1: AppComponent — signals for UI state

Convert `showWelcomePopup` and `showDoMoreBanner` to `signal<boolean>(false)`. Replace all `.property = value` assignments with `.set(value)`. Remove `cdr.detectChanges()` calls. Verify the welcome popup still shows/hides based on `VisitService`.

WIP commit after Phase 1.

### Phase 2: AppComponent — remove AfterViewInit + ChangeDetectorRef

Move the initialization logic from `ngAfterViewInit` into the constructor using `afterNextRender()`. Remove the `AfterViewInit` interface and `ChangeDetectorRef` injection. Verify the do-more banner still appears after 4 seconds.

WIP commit after Phase 2.

### Phase 3: PopupComponent — replace setTimeout(0) with afterNextRender

Replace the `setTimeout(() => { this.visibleClass = 'is-visible'; this.#cdr.detectChanges(); }, 0)` pattern in `openPopup()`. Use `afterNextRender` appropriately (research the right hook point for this case — it may need an `effect()` or a different approach since it's triggered imperatively from a method call). Remove the now-unnecessary `cdr.detectChanges()` calls from `PopupComponent`. Keep the `setTimeout(300)` in `closePopup()`.

WIP commit after Phase 3.
