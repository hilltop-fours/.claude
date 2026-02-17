#!/usr/bin/env bash
FRONTEND_PATH="$1"
BASELINE="$2"
cd "$FRONTEND_PATH" || exit 1

echo "### Prettier"
echo ""

PRETTIER_FILES=$(git diff "$BASELINE"...HEAD --name-only --diff-filter=ACMR -- 'src/*.ts' 'src/*.html' 'src/*.scss' 'src/**/*.ts' 'src/**/*.html' 'src/**/*.scss' 2>/dev/null | sort -u)

if [ -z "$PRETTIER_FILES" ]; then
  echo "- [x] No files to check -- PASS"
  echo ""
  exit 0
fi

FAIL_FILES=""
FAIL_COUNT=0
TOTAL_COUNT=0

while IFS= read -r file; do
  if [ -f "$file" ]; then
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    if ! npx prettier --check "$file" >/dev/null 2>&1; then
      FAIL_COUNT=$((FAIL_COUNT + 1))
      FAIL_FILES="$FAIL_FILES
  - \`$file\`"
    fi
  fi
done <<< "$PRETTIER_FILES"

if [ $FAIL_COUNT -eq 0 ]; then
  echo "- [x] Checked $TOTAL_COUNT files -- PASS"
else
  echo "- [ ] Checked $TOTAL_COUNT files -- **FAIL**: $FAIL_COUNT file(s) need formatting$FAIL_FILES"
fi
echo ""
