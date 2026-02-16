# Dead Code Detection Rules

These are **custom validation rules** for detecting code that is defined but never used. Dead code wastes memory, reduces readability, and may indicate incomplete refactoring or bugs.

**Why custom rules:** SonarQube doesn't detect unused private class members in our TypeScript setup, so we use a combination of TypeScript compiler flags, ESLint rules, and manual grep-based inspection.

**Critical gap this closes:** During code review of feature/108600/109824, an unused Observable method `canEditTrafficSign()` (22 lines) was discovered. The validation workflow missed it entirely because dead code detection wasn't formalized. These rules prevent similar cases from passing validation in the future.

---

## Rule 1: Unused local variables

Do not declare local variables that are never read after assignment. Unused variables waste memory, reduce code readability, and may indicate incomplete refactoring or logical errors.

**Detection method:**
```bash
npx tsc --noEmit --noUnusedLocals
```

**Fix:** Remove the unused variable declaration entirely, or if it's the result of a necessary operation with side effects, prefix the variable name with an underscore (`_variableName`) to indicate intentional non-use.

**Example - WRONG** (unused variable):
```typescript
getData() {
  const result = this.fetchData();  // ❌ Declared but never used
  return this.fallbackData;
}
```

**Example - CORRECT** (variable removed):
```typescript
getData() {
  return this.fallbackData;
}
```

**Example - CORRECT** (intentional non-use):
```typescript
subscribe() {
  const _subscription = this.data$.subscribe();  // ✅ Underscore shows intent
}
```

---

## Rule 2: Unused function parameters

Do not define function or method parameters that are never used in the function body. Unused parameters confuse readers about the function's purpose and may indicate incomplete implementation.

**Detection method:**
```bash
npx tsc --noEmit --noUnusedParameters
```

**Fix:** Remove the unused parameter from the function signature and all call sites. If the parameter is required by an interface or base class, prefix it with an underscore (`_paramName`) to indicate intentional non-use.

**Example - WRONG**:
```typescript
calculateTotal(items: Item[], discount: number): number {  // ❌ discount never used
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

**Example - CORRECT**:
```typescript
calculateTotal(items: Item[]): number {  // ✅ Removed unused parameter
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

**Example - CORRECT** (interface implementation):
```typescript
class SimpleProcessor implements DataProcessor {
  process(data: string, _options: ProcessOptions): void {  // ✅ Underscore prefix
    console.info(data);
  }
}
```

**Angular exception:** Angular event handlers often omit unused event parameters:
```typescript
onButtonClick() {  // ✅ Acceptable - no unused parameter needed
  this.save();
}
```

---

## Rule 3: Dead stores/assignments

Do not assign a value to a variable if that value is never read before the variable is reassigned or goes out of scope. Dead stores waste computation and may indicate logical errors.

**Detection method:** Manual code inspection (no automated tool configured)

**Fix:** Remove the unnecessary assignment, or fix the logic to use the first value.

**Example - WRONG**:
```typescript
getStatus(): string {
  let status = 'pending';  // ❌ Immediately overwritten, never read
  status = this.currentStatus();
  return status;
}
```

**Example - CORRECT**:
```typescript
getStatus(): string {
  return this.currentStatus();
}
```

---

## Rule 4: Unused private class members ⭐

**This is the critical rule that catches dead methods like `canEditTrafficSign()`.**

Detect private methods and properties that are defined in a class but never called or accessed anywhere in that class. This is a common form of dead code that accumulates during refactoring.

**Detection method:**
```bash
# Automated with ESLint:
npx eslint file.ts --rule "no-unused-private-class-members: error"

# Manual with grep:
# 1. Extract all private method names
grep -n "^\s*\(private\|#\).*(" file.ts

# 2. For each method, search within the codebase
grep -r "methodName" --include="*.ts" --include="*.html" .

# 3. If only one result (the definition), it's unused
```

**Fix:** Delete the unused private method or property entirely.

**Example - WRONG**:
```typescript
export class UserService {
  #userData = signal<User | undefined>(undefined);

  getUser(): Signal<User | undefined> {
    return this.#userData.asReadonly();
  }

  // ❌ DEAD CODE: Method defined but never called
  #loadUserFromCache(): User | undefined {
    return localStorage.getItem('user')
      ? JSON.parse(localStorage.getItem('user')!)
      : undefined;
  }
}
```

**Example - CORRECT**:
```typescript
export class UserService {
  #userData = signal<User | undefined>(undefined);

  getUser(): Signal<User | undefined> {
    return this.#userData.asReadonly();
  }

  // ✅ Dead method removed entirely
}
```

### Real-World Example from This Codebase

**The case that motivated this rule:**

In `RoadSectionAuthService` (commit `ac2f2e34`), an Observable-based method `canEditTrafficSign()` was defined but **never called anywhere in the codebase**. A Signal-based equivalent `canEditTrafficSignSignal()` existed and was being used instead:

```typescript
export class RoadSectionAuthService {
  // ❌ WRONG - This Observable method was dead code (removed in commit ac2f2e34)
  canEditTrafficSign(trafficSign: TrafficSign): Observable<boolean> {
    return combineLatest([
      this.#authService.isAdmin$,
      this.#userRepository.organization$
    ]).pipe(
      map(([isAdmin, organization]) => {
        if (isAdmin) return true;
        if (!trafficSign.owner?.code) return true;
        const userRoadAuthorities = organization?.roadAuthorities ?? [];
        return userRoadAuthorities.some(
          (ra) => ra.type === trafficSign.owner!.type &&
                  this.#isEqualCode(ra.code, trafficSign.owner!.code),
        );
      }),
    );
  }

  // ✅ This Signal version was actually being used
  canEditTrafficSignSignal(trafficSign: Signal<TrafficSign | undefined>): Signal<boolean> {
    return computed(() => {
      // Same logic but with Signals
    });
  }
}
```

**Detection:** Search revealed the method was only defined, never called:
```bash
$ grep -r "canEditTrafficSign" --include="*.ts" --include="*.html" .
src/app/core/services/road-section-auth.service.ts:138:  canEditTrafficSign(trafficSign: TrafficSign): Observable<boolean> {
# Only one result = unused method
```

**Impact:** 22 lines of duplicated logic that served no purpose. Validation didn't catch this because dead code detection wasn't part of the formal workflow.

**Prevention:** After migrating code patterns (Observable → Signal, etc.), always search for and remove old implementations.

---

## Rule 5: Unreachable code

Detect code that appears after statements that unconditionally exit the function (`return`, `throw`, `break`, `continue`). Unreachable code is never executed and may confuse readers.

**Detection method:**
```bash
# TypeScript compiler:
npx tsc --noEmit --allowUnreachableCode=false

# Manual inspection:
grep -n -A 2 "return.*;" file.ts
# Check if non-closing-brace lines appear after return
```

**Fix:** Remove the unreachable code.

**Example - WRONG**:
```typescript
getStatus(): string {
  return 'active';
  console.info('Never executes');  // ❌ Unreachable
}
```

**Example - CORRECT**:
```typescript
getStatus(): string {
  return 'active';
}
```

---

## Summary: Detection Methods

| Rule | Automated Check | Manual Check |
|------|----------------|--------------|
| **Rule 1**: Unused local variables | ✅ `tsc --noUnusedLocals` | - |
| **Rule 2**: Unused parameters | ✅ `tsc --noUnusedParameters` | - |
| **Rule 3**: Dead stores | - | ✅ Code inspection |
| **Rule 4**: Unused private members | ✅ ESLint `no-unused-private-class-members` | ✅ grep pattern |
| **Rule 5**: Unreachable code | ✅ `tsc --allowUnreachableCode=false` | ✅ grep after return |

**Integration:** These checks are part of the mandatory validation workflow in `CLAUDE.md` (Phase 2 automated checks, Phase 3 manual review).
