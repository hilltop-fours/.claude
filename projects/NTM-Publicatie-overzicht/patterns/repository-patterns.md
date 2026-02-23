# Repository Patterns - NTM Publicatie Overzicht

Rules for what code belongs in `*.repository.ts` files and what does not.
Based on analysis of all 16 existing repositories in the codebase.

---

## What a Repository Is

A repository is a **combined HTTP orchestrator and state container**.
It triggers HTTP calls via an injected service, pipes the result into a `@ngneat/elf` store,
and exposes the state reactively via observables and synchronous getters.

All repositories extend `BaseRepository`, which provides the HTTP→state lifecycle methods.

Repositories are the primary data access layer in this application.
Components and other consumers never call services directly — they always go through a repository.

---

## BaseRepository

Every repository extends `BaseRepository` (`src/app/core/data-access/base-repository.ts`).

**What it provides**:

| Method | Purpose |
|--------|---------|
| `onHttpPending<T>(key)` | Sets store key to `{ status: PENDING }` |
| `onHttpSuccess<T>(key, data, toast?, params?)` | Sets store key to `{ status: SUCCESS, data }`, shows optional toast |
| `onHttpError<T>(key, error, toast?)` | Sets store key to `{ status: ERROR, error }`, shows optional toast |
| `updateStoreData<T>(key, data, params?)` | Updates store data without status change |
| `showSuccessToast(message)` | Shows toastr success notification |
| `showErrorToast(message)` | Shows toastr error notification |
| `markFetched(key)` | Records a cache timestamp for a key |
| `isFresh(key)` | Returns true if key was fetched within the last 1000ms (deduplication guard) |
| `translate` | Injected `TranslateService` for toast messages |

---

## Standard Repository Structure

### File-level structure

```typescript
// 1. Imports

// 2. Props interface — one key per data slice
interface MyFeatureProps {
  items: HttpState<IItem[]>;
  item: HttpState<IItem>;
  create: HttpState<IItem>;
  update: HttpState<IItem>;
  delete: HttpState<void>;
}

// 3. Initial state — all keys start as IDLE
const initialState: MyFeatureProps = {
  items: { status: HttpStatus.IDLE },
  item: { status: HttpStatus.IDLE },
  create: { status: HttpStatus.IDLE },
  update: { status: HttpStatus.IDLE },
  delete: { status: HttpStatus.IDLE },
};

// 4. Store — created OUTSIDE the class as module-level const
const store = createStore({ name: 'my-feature' }, withProps<MyFeatureProps>(initialState));

// 5. Class
@UntilDestroy()
@Injectable({ providedIn: 'root' })
export class MyFeatureRepository extends BaseRepository {
  // 5a. Private service injection (# prefix)
  readonly #myFeatureService = inject(MyFeatureService);

  // 5b. Observable fields (readonly, no $-getter accessor)
  readonly items$: Observable<HttpState<IItem[]>> = store.pipe(select((state) => state.items));

  // 5c. Signal fields (optional, for template binding)
  readonly itemsSignal = toSignal(this.items$.pipe(map((s) => s.data ?? [])), { initialValue: [] });

  // 5d. Constructor — only calls super(store)
  constructor() {
    super(store);
  }

  // 5e. Synchronous getters (for imperative code)
  get items(): IItem[] | undefined {
    return store.getValue().items.data;
  }

  // 5f. Action methods
  getAll(): Observable<HttpState<IItem[]>> { ... }
}
```

---

## Observable Exposure Patterns

There are two ways observables appear in NTM repos. **Use the `readonly` field pattern** — it is consistent with the majority of repos and avoids SonarQube naming violations.

### Preferred: `readonly` field

```typescript
// ✅ Use this
readonly items$: Observable<HttpState<IItem[]>> = store.pipe(select((state) => state.items));
readonly create$: Observable<HttpState<IItem>> = store.pipe(select((state) => state.create));
```

### Avoid: `get` accessor with `$` suffix

```typescript
// ❌ Avoid — SonarQube typescript:S100 violation
// The $ suffix makes the name non-compliant with the naming regex ^[_a-z][a-zA-Z0-9]*
get items$(): Observable<HttpState<IItem[]>> {
  return store.pipe(select((state) => state.items));
}
```

**Why the getter causes a SonarQube issue**: the `$` suffix violates the `^[_a-z][a-zA-Z0-9]*` naming rule for functions/methods. A `readonly` field is not a function, so it is not subject to this rule.

**When getters are acceptable**: use a `get` accessor (without `$`) for synchronous data only:
```typescript
get items(): IItem[] | undefined {
  return store.getValue().items.data;
}
```

---

## Standard Action Method Pattern

Every action method follows the same shape:

```typescript
getAll(): Observable<HttpState<IItem[]>> {
  this.onHttpPending<MyFeatureProps>('items');           // 1. Set PENDING

  this.#myFeatureService
    .getAll()
    .pipe(untilDestroyed(this))                          // 2. Auto-unsubscribe
    .subscribe({
      next: (items: IItem[]) =>
        this.onHttpSuccess<MyFeatureProps>('items', items),   // 3. Set SUCCESS
      error: (error) =>
        this.onHttpError<MyFeatureProps>(                     // 4. Set ERROR + toast
          'items',
          error,
          this.translate.instant('DATA_ACCESS.MY_FEATURE.GET_ALL.ERROR')
        ),
    });

  return store.pipe(select((state) => state.items));    // 5. Return observable
}
```

**Key rules**:
- Always set PENDING before triggering HTTP
- Always pass a translated error toast message to `onHttpError`
- Always return the store observable (not the HTTP observable)
- Use `untilDestroyed(this)` for `@UntilDestroy()` classes, or `takeUntilDestroyed(this.#destroyRef)` when `DestroyRef` is injected

### Variant: with success toast

```typescript
next: (item: IItem) =>
  this.onHttpSuccess<MyFeatureProps>(
    'create',
    item,
    this.translate.instant('DATA_ACCESS.MY_FEATURE.CREATE.SUCCESS')  // optional 3rd arg
  ),
```

### Variant: with post-success side effect (refresh)

```typescript
next: (item: IItem) => {
  this.onHttpSuccess<MyFeatureProps>('create', item, this.translate.instant('...SUCCESS'));
  this.#refreshList();   // re-fetch related data after mutation
},
complete: () => this.refreshPagedResponses(),
```

### Variant: using `HttpResponse<T>` (wraps state with typed `data`)

Some repos return `HttpResponse<T>` (via `toResponse()`) instead of `HttpState<T>`. Use this when consumers need typed access to the data without unwrapping the state themselves:

```typescript
get update$(): Observable<HttpResponse<IItem>> {
  return store.pipe(select((state) => state.update)).pipe(map((state) => toResponse(state)));
}
```

---

## Store Conventions

### Store definition
- Always created **outside the class** as a module-level `const`
- One store per repository — never share stores between files
- Name matches the feature: `createStore({ name: 'publications' }, ...)`
- Always use `withProps<TProps>(initialState)`

### Store access patterns

| Use case | Pattern |
|----------|---------|
| Reactive (template/subscription) | `store.pipe(select((state) => state.key))` |
| Synchronous (imperative) | `store.getValue().key` or `store.getValue().key.data` |
| Update single prop | `store.update((state) => ({ ...state, [key]: newValue }))` |

### HttpState shape

Every store prop is typed as `HttpState<T>`:

```typescript
interface HttpState<T> {
  status: HttpStatus;   // IDLE | PENDING | SUCCESS | ERROR
  data?: T;
  error?: unknown;
  params?: Params;      // preserved for paged responses that need refreshing
}
```

`params` is stored alongside data when the request used query params — this allows `refresh*` methods to re-trigger the same request without needing to remember the params.

---

## Decorator & Lifecycle Conventions

### Always use `@UntilDestroy()` + `untilDestroyed(this)`

```typescript
@UntilDestroy()
@Injectable({ providedIn: 'root' })
export class MyRepository extends BaseRepository { ... }
```

All service subscriptions inside the class must use `.pipe(untilDestroyed(this))`.

### Alternative: `DestroyRef` + `takeUntilDestroyed`

Newer repos (e.g., `InfoMessageRepository`, `DataPublicationRepository`) inject `DestroyRef` and use `takeUntilDestroyed(this.#destroyRef)`. Both approaches are acceptable — use whichever is consistent with the rest of the file.

```typescript
readonly #destroyRef = inject(DestroyRef);

this.#service.getAll()
  .pipe(takeUntilDestroyed(this.#destroyRef))
  .subscribe({ ... });
```

---

## Signals (Emerging Pattern)

Some repos expose signals via `toSignal()` for direct template binding without `async` pipe:

```typescript
readonly notificationCountSignal: Signal<number> = toSignal(this.notificationCount$, { initialValue: 0 });
readonly selection = toSignal(this.selection$, { initialValue: [] });
```

This is acceptable and encouraged for computed/derived values frequently used in templates. Always provide `initialValue` to avoid injection context issues.

---

## UI State in Repositories

Repositories can hold non-HTTP UI state alongside HTTP state. Use a plain key in `withProps` and update it directly:

```typescript
interface DataImportProps {
  dataImports: HttpState<PagedResponse<DataImport>>;
  selection: string[];  // UI state — not HttpState
}

// Update UI state directly (no onHttpPending/Success/Error)
store.update((state) => ({ ...state, selection: newSelection }));
```

**When to use this**: selection state, preview state, pagination preferences — anything that needs to be reactive but is not the result of an HTTP call.

---

## What Does NOT Belong in a Repository

| Code type | Where it belongs instead |
|-----------|--------------------------|
| Raw HTTP calls (`HttpClient` usage) | Service (`*.service.ts`) |
| URL construction / query param building | Service |
| Data transformation for API (serialization) | Service |
| Route navigation | Component or guard |
| Form validation | Component |
| Template/rendering logic | Component or pipe |
| Heavy data transformation for display only | Pipe or presentation service |

**Note**: Unlike a strict separation model, NTM repositories DO call services and handle the HTTP lifecycle. This is intentional — services are thin HTTP wrappers, and repositories own orchestration + state. Data transformations that are tightly coupled to state updates (e.g., sorting notifications by date, validating publication URLs after fetch) are acceptable inside the repository's `next` callback.

---

## Refresh Patterns

When a mutation should re-fetch related lists, use a `refresh*` method:

```typescript
refreshPagedResponses() {
  if (this.#dataPublications) {
    this.getAll(this.#dataPublications.params);  // re-uses stored params
  }
}
```

Call it from `complete:` (after success) or directly after `onHttpSuccess`:

```typescript
complete: () => this.refreshPagedResponses(),
```

Only refresh when the data is already loaded (`status === SUCCESS` or data is present). Do not trigger refreshes from IDLE state.

---

## Deduplication / Cache Guard

`BaseRepository` provides a 1-second TTL cache via `markFetched` / `isFresh`. Use it for read-only detail fetches that may be triggered multiple times in quick succession:

```typescript
find(id: string): Observable<HttpState<IDataPublication>> {
  const key = `dataPublication|${id}`;
  if (this.isFresh(key)) {
    return store.pipe(select((state) => state.dataPublication));  // return existing state
  }

  this.onHttpPending<MyProps>('dataPublication');
  this.#service.find(id).pipe(untilDestroyed(this)).subscribe({
    next: (item) => {
      this.markFetched(key);
      this.onHttpSuccess<MyProps>('dataPublication', item);
    },
    ...
  });

  return store.pipe(select((state) => state.dataPublication));
}
```

Only use this for `find`/`get` type calls, not for mutations.

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| File | `{entity-name}.repository.ts` (kebab-case) | `data-publication.repository.ts` |
| Class | `{EntityName}Repository` (PascalCase) | `DataPublicationRepository` |
| Store name | kebab-case string matching entity | `'data-imports'`, `'publications'` |
| Props interface | `{EntityName}Props` | `DataImportProps` |
| Service field | `#${entityName}Service` (private, `#`) | `#dataImportService` |
| Observable fields | `{name}$` (readonly field, not getter) | `readonly items$` |
| Synchronous getters | `get {name}()` (no `$`) | `get items()` |
| Signal fields | `{name}Signal` or `{name}` (no `$`) | `notificationCountSignal`, `selection` |
| Translation keys | `DATA_ACCESS.{ENTITY}.{ACTION}.ERROR/SUCCESS` | `DATA_ACCESS.USER.GET_ALL.ERROR` |

---

## File Location

All repositories live under `src/app/core/data-access/{feature}/`:

```
src/app/core/data-access/
  base-repository.ts
  publications/
    data-publication.repository.ts
    data-publication.service.ts
    types/
  user/
    user.repository.ts
    user.service.ts
    types/
  ...
```

Exception: feature-specific repositories that are tightly scoped to a module may live inside the module's `state/` folder (e.g., `dataset/state/dataset.repository.ts`, `standards/state/standards.repository.ts`).

---

## Complete Minimal Example

```typescript
import { Injectable, inject } from '@angular/core';
import { createStore, select, withProps } from '@ngneat/elf';
import { UntilDestroy, untilDestroyed } from '@ngneat/until-destroy';
import { Observable } from 'rxjs';
import { BaseRepository } from '../base-repository';
import { HttpState, HttpStatus } from '../types';
import { IMyModel } from './types';
import { MyService } from './my.service';

interface MyProps {
  items: HttpState<IMyModel[]>;
  item: HttpState<IMyModel>;
}

const initialState: MyProps = {
  items: { status: HttpStatus.IDLE },
  item: { status: HttpStatus.IDLE },
};

const store = createStore({ name: 'my-feature' }, withProps<MyProps>(initialState));

@UntilDestroy()
@Injectable({ providedIn: 'root' })
export class MyRepository extends BaseRepository {
  readonly #myService = inject(MyService);

  readonly items$: Observable<HttpState<IMyModel[]>> = store.pipe(select((state) => state.items));
  readonly item$: Observable<HttpState<IMyModel>> = store.pipe(select((state) => state.item));

  constructor() {
    super(store);
  }

  get items(): IMyModel[] | undefined {
    return store.getValue().items.data;
  }

  getAll(): Observable<HttpState<IMyModel[]>> {
    this.onHttpPending<MyProps>('items');

    this.#myService
      .getAll()
      .pipe(untilDestroyed(this))
      .subscribe({
        next: (items: IMyModel[]) => this.onHttpSuccess<MyProps>('items', items),
        error: (error) =>
          this.onHttpError<MyProps>('items', error, this.translate.instant('DATA_ACCESS.MY_FEATURE.GET_ALL.ERROR')),
      });

    return this.items$;
  }

  find(id: string): Observable<HttpState<IMyModel>> {
    this.onHttpPending<MyProps>('item');

    this.#myService
      .find(id)
      .pipe(untilDestroyed(this))
      .subscribe({
        next: (item: IMyModel) => this.onHttpSuccess<MyProps>('item', item),
        error: (error) =>
          this.onHttpError<MyProps>('item', error, this.translate.instant('DATA_ACCESS.MY_FEATURE.FIND.ERROR')),
      });

    return this.item$;
  }
}
```
