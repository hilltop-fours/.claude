#!/usr/bin/env bash
FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "- [ ] File not found: \`$FILE\`"
  exit 1
fi

# Helper: run grep check and format result
check_grep() {
  local LABEL="$1"
  local PATTERN="$2"
  local SEVERITY="${3:-FAIL}"

  MATCHES=$(grep -n "$PATTERN" "$FILE" 2>/dev/null || true)
  if [ -z "$MATCHES" ]; then
    echo "- [x] $LABEL -- PASS"
  else
    LINE_COUNT=$(echo "$MATCHES" | wc -l | tr -d ' ')
    echo "- [ ] $LABEL -- **$SEVERITY** ($LINE_COUNT occurrence(s))"
    while IFS= read -r line; do
      LINE_NUM=$(echo "$line" | cut -d: -f1)
      LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
      echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
    done <<< "$MATCHES"
  fi
}

# ===== CONTROL FLOW SYNTAX =====
echo "**Control Flow Syntax**"
echo ""

check_grep "*ngIf (use @if)" '\*ngIf' "FAIL"
check_grep "*ngFor (use @for)" '\*ngFor' "FAIL"
check_grep "*ngSwitch (use @switch)" '\*ngSwitch' "FAIL"

echo ""

# ===== BINDINGS =====
echo "**Bindings**"
echo ""

check_grep "[ngClass] (use [class])" '\[ngClass\]' "FAIL"
check_grep "[ngStyle] (use [style])" '\[ngStyle\]' "FAIL"

echo ""

# ===== ACCESSIBILITY =====
echo "**Accessibility**"
echo ""

# aria-required on radio/checkbox (should be on fieldset)
ARIA_RADIO=$(grep -n 'type="radio".*aria-required\|type="checkbox".*aria-required\|aria-required.*type="radio"\|aria-required.*type="checkbox"' "$FILE" 2>/dev/null || true)
if [ -z "$ARIA_RADIO" ]; then
  echo "- [x] aria-required placement -- PASS"
else
  LINE_COUNT=$(echo "$ARIA_RADIO" | wc -l | tr -d ' ')
  echo "- [ ] aria-required on radio/checkbox (move to fieldset) -- **FAIL** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    echo "  - Line $LINE_NUM"
  done <<< "$ARIA_RADIO"
fi

echo ""
