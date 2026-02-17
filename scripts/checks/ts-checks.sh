#!/usr/bin/env bash
FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "- [ ] File not found: \`$FILE\`"
  exit 1
fi

# Determine file subtype
IS_COMPONENT_TYPE=false
echo "$FILE" | grep -qE '\.(component|directive|pipe)\.ts$' && IS_COMPONENT_TYPE=true

# Helper: run grep check and format result
check_grep() {
  local LABEL="$1"
  local PATTERN="$2"
  local SEVERITY="${3:-FAIL}"

  MATCHES=$(grep -n "$PATTERN" "$FILE" 2>/dev/null | grep -v '^\s*//' || true)
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

# ===== ANGULAR SYNTAX =====
echo "**Angular Syntax**"
echo ""

check_grep "@Input() decorator (use input())" "@Input(" "FAIL"
check_grep "@Output() decorator (use output())" "@Output(" "FAIL"
check_grep "@ViewChild() decorator (use viewChild())" "@ViewChild(" "FAIL"
check_grep "@ViewChildren() decorator (use viewChildren())" "@ViewChildren(" "FAIL"
check_grep "@ContentChild() decorator (use contentChild())" "@ContentChild(" "FAIL"
check_grep "@ContentChildren() decorator (use contentChildren())" "@ContentChildren(" "FAIL"
check_grep "@HostListener() decorator" "@HostListener(" "FAIL"

if $IS_COMPONENT_TYPE; then
  check_grep "toSignal() in component (move to service)" "toSignal(" "FAIL"
fi

echo ""

# ===== TYPESCRIPT QUALITY =====
echo "**TypeScript Quality**"
echo ""

# any type - match : any, as any, <any> but exclude comments
ANY_MATCHES=$(grep -n '\bany\b' "$FILE" 2>/dev/null | grep -v '^\s*//' | grep -v '^\s*\*' | grep -E ':\s*any\b|as\s+any\b|<any>' || true)
if [ -z "$ANY_MATCHES" ]; then
  echo "- [x] No \`any\` type usage -- PASS"
else
  LINE_COUNT=$(echo "$ANY_MATCHES" | wc -l | tr -d ' ')
  echo "- [ ] \`any\` type usage -- **FAIL** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
    echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
  done <<< "$ANY_MATCHES"
fi

# Nested subscribes - flag if multiple .subscribe( calls exist
SUB_MATCHES=$(grep -n '\.subscribe(' "$FILE" 2>/dev/null | grep -v '^\s*//' || true)
if [ -n "$SUB_MATCHES" ] && [ "$(echo "$SUB_MATCHES" | wc -l | tr -d ' ')" -gt 1 ]; then
  SUB_COUNT=$(echo "$SUB_MATCHES" | wc -l | tr -d ' ')
  echo "- [ ] Multiple .subscribe() calls ($SUB_COUNT) -- **REVIEW** (verify no nesting)"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    echo "  - Line $LINE_NUM"
  done <<< "$SUB_MATCHES"
else
  echo "- [x] Nested subscribes -- PASS"
fi

check_grep "// COMPLEXITY: markers (must remove before PR)" "// COMPLEXITY:" "FAIL"

# console statements - log, warn, error, debug
CONSOLE_MATCHES=$(grep -n 'console\.\(log\|warn\|error\|debug\)(' "$FILE" 2>/dev/null | grep -v '^\s*//' || true)
if [ -z "$CONSOLE_MATCHES" ]; then
  echo "- [x] No forbidden console statements -- PASS"
else
  LINE_COUNT=$(echo "$CONSOLE_MATCHES" | wc -l | tr -d ' ')
  echo "- [ ] Forbidden console statements -- **FAIL** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
    echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
  done <<< "$CONSOLE_MATCHES"
fi

# Magic numbers - numbers >= 2 that are not in imports, decorators, or comments
# Exclude: 0, 1, -1, array indices, common patterns
MAGIC_MATCHES=$(grep -nE '[^a-zA-Z0-9_\.][0-9]{2,}[^0-9a-zA-Z_px%emrsvh]|[^a-zA-Z0-9_\.]=[[:space:]]*[2-9][^0-9]' "$FILE" 2>/dev/null \
  | grep -v '^\s*//' \
  | grep -v '^\s*\*' \
  | grep -v 'import ' \
  | grep -v '@' \
  | grep -v '\.spec\.' \
  | grep -v 'enum ' \
  || true)
if [ -z "$MAGIC_MATCHES" ]; then
  echo "- [x] Magic numbers -- PASS"
else
  LINE_COUNT=$(echo "$MAGIC_MATCHES" | wc -l | tr -d ' ')
  echo "- [ ] Potential magic numbers -- **REVIEW** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
    echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
  done <<< "$MAGIC_MATCHES"
fi

echo ""

# ===== STYLE PREFERENCES =====
echo "**Style Preferences**"
echo ""

# private keyword (should use #) - exclude constructor params and comments
PRIVATE_MATCHES=$(grep -n '^\s*private\s' "$FILE" 2>/dev/null | grep -v 'constructor' | grep -v '^\s*//' || true)
if [ -z "$PRIVATE_MATCHES" ]; then
  echo "- [x] Private fields use # syntax -- PASS"
else
  LINE_COUNT=$(echo "$PRIVATE_MATCHES" | wc -l | tr -d ' ')
  echo "- [ ] Private fields should use # syntax -- **FAIL** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
    echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
  done <<< "$PRIVATE_MATCHES"
fi

# readonly missing on inject() calls
INJECT_NO_READONLY=$(grep -n 'inject(' "$FILE" 2>/dev/null | grep -v 'readonly' | grep -v '^\s*//' || true)
if [ -z "$INJECT_NO_READONLY" ]; then
  echo "- [x] readonly on inject() calls -- PASS"
else
  LINE_COUNT=$(echo "$INJECT_NO_READONLY" | wc -l | tr -d ' ')
  echo "- [ ] readonly missing on inject() -- **FAIL** ($LINE_COUNT occurrence(s))"
  while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    LINE_CONTENT=$(echo "$line" | cut -d: -f2- | sed 's/^ *//' | cut -c1-100)
    echo "  - Line $LINE_NUM: \`$LINE_CONTENT\`"
  done <<< "$INJECT_NO_READONLY"
fi

echo ""
