#!/usr/bin/env bash
FRONTEND_PATH="$1"
shift
TS_FILES="$*"

echo "### JSDoc Detection"
echo ""

if [ -z "$TS_FILES" ]; then
  echo "- [x] No .ts files to check -- PASS"
  echo ""
  exit 0
fi

VIOLATIONS=""
VIOLATION_COUNT=0

for file in $TS_FILES; do
  FULL_PATH="$FRONTEND_PATH/$file"
  if [ -f "$FULL_PATH" ]; then
    MATCHES=$(grep -n '^\s*/\*\*' "$FULL_PATH" 2>/dev/null || true)
    if [ -n "$MATCHES" ]; then
      MATCH_COUNT=$(echo "$MATCHES" | wc -l | tr -d ' ')
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS="$VIOLATIONS
  - \`$file\`: $MATCH_COUNT JSDoc block(s)"
      while IFS= read -r line; do
        LINE_NUM=$(echo "$line" | cut -d: -f1)
        VIOLATIONS="$VIOLATIONS
    - Line $LINE_NUM"
      done <<< "$MATCHES"
    fi
  fi
done

if [ $VIOLATION_COUNT -eq 0 ]; then
  echo "- [x] No JSDoc blocks found in changed .ts files -- PASS"
else
  echo "- [ ] JSDoc blocks found in $VIOLATION_COUNT file(s) -- **REVIEW** (may be legitimate 'why' comments)$VIOLATIONS"
fi
echo ""
