#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CLAUDE_ROOT")"
REPORT_FILE="$SCRIPT_DIR/report.md"

# ===== PROJECT DETECTION =====
case "$PROJECT_ROOT" in
  *GRG-Wegkenmerken-verkeersborden*)
    PROJECT="GRG"
    FRONTEND_DIR="traffic-sign-frontend"
    ;;
  *NTM-Publicatie-overzicht*)
    PROJECT="NTM"
    FRONTEND_DIR="ntm-frontend"
    ;;
  *BER-Bereikbaarheidskaart*)
    PROJECT="BER"
    FRONTEND_DIR="accessibility-map-frontend"
    ;;
  *)
    echo "ERROR: Cannot detect project from path: $PROJECT_ROOT"
    exit 1
    ;;
esac

FRONTEND_PATH="$PROJECT_ROOT/$FRONTEND_DIR"

if [ ! -d "$FRONTEND_PATH" ]; then
  echo "ERROR: Frontend directory not found: $FRONTEND_PATH"
  exit 1
fi

# ===== ENSURE TS-MORPH IS AVAILABLE =====
if [ ! -d "$SCRIPT_DIR/node_modules/ts-morph" ]; then
  echo "Installing dependencies..."
  cd "$SCRIPT_DIR"
  npm install --silent
fi

if [ ! -f "$SCRIPT_DIR/dist/class-structure.js" ]; then
  echo "Compiling class-structure checker..."
  cd "$SCRIPT_DIR"
  npx tsc -p tsconfig.json
fi

# ===== BASELINE AND CHANGED FILES =====
cd "$FRONTEND_PATH"

BASELINE=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
if [ -z "$BASELINE" ]; then
  echo "ERROR: Cannot determine merge-base with origin/main"
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
BASELINE_SHORT=$(echo "$BASELINE" | cut -c1-8)

# Get all changed files in src/ only, excluding spec files
ALL_CHANGED=$(git diff "$BASELINE"...HEAD --name-only --diff-filter=ACMR -- 'src/' 2>/dev/null || echo "")

if [ -z "$ALL_CHANGED" ]; then
  echo "No changed files in src/ since divergence from main."
  {
    echo "# Validation Report"
    echo ""
    echo "**Date**: $(date '+%Y-%m-%d %H:%M')"
    echo "**Project**: $PROJECT"
    echo "**Branch**: \`$BRANCH\`"
    echo "**Baseline**: \`$BASELINE_SHORT\` (merge-base with origin/main)"
    echo "**Files changed**: 0"
    echo ""
    echo "No changes detected in \`src/\` since branch diverged from main."
  } > "$REPORT_FILE"
  echo "Report written to: $REPORT_FILE"
  exit 0
fi

# Categorize files (exclude .spec.ts from validation)
TS_FILES=$(echo "$ALL_CHANGED" | grep '\.ts$' | grep -v '\.spec\.ts$' || true)
HTML_FILES=$(echo "$ALL_CHANGED" | grep '\.html$' || true)
SCSS_FILES=$(echo "$ALL_CHANGED" | grep '\.scss$' || true)

# Sub-categorize .ts files
TS_COMPONENT_FILES=$(echo "$TS_FILES" | grep -E '\.(component|service|repository|directive|pipe)\.ts$' || true)
TS_OTHER_FILES=$(echo "$TS_FILES" | grep -vE '\.(component|service|repository|directive|pipe)\.ts$' || true)

TOTAL_FILES=$(echo "$ALL_CHANGED" | wc -l | tr -d ' ')
TS_COUNT=$(echo "$TS_FILES" | grep -c '.' || echo "0")
HTML_COUNT=$(echo "$HTML_FILES" | grep -c '.' || echo "0")
SCSS_COUNT=$(echo "$SCSS_FILES" | grep -c '.' || echo "0")

# ===== TRACKING COUNTS =====
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_REVIEW=0

# ===== WRITE REPORT HEADER =====
{
  echo "# Validation Report"
  echo ""
  echo "**Date**: $(date '+%Y-%m-%d %H:%M')"
  echo "**Project**: $PROJECT"
  echo "**Branch**: \`$BRANCH\`"
  echo "**Baseline**: \`$BASELINE_SHORT\` (merge-base with origin/main)"
  echo "**Files changed**: $TOTAL_FILES (.ts: $TS_COUNT, .html: $HTML_COUNT, .scss: $SCSS_COUNT)"
  echo ""
  echo "**Changed files:**"
  echo '```'
  git diff "$BASELINE"...HEAD --stat -- 'src/' 2>/dev/null || true
  echo '```'
  echo ""
  echo "---"
  echo ""
} > "$REPORT_FILE"

# ===== SECTION 1: AUTOMATED CHECKS =====
{
  echo "## 1. Automated Checks"
  echo ""
} >> "$REPORT_FILE"

echo "Running build..."
bash "$SCRIPT_DIR/checks/build.sh" "$FRONTEND_PATH" >> "$REPORT_FILE" 2>&1

echo "Running lint..."
bash "$SCRIPT_DIR/checks/lint.sh" "$FRONTEND_PATH" >> "$REPORT_FILE" 2>&1

echo "Running prettier..."
bash "$SCRIPT_DIR/checks/prettier.sh" "$FRONTEND_PATH" "$BASELINE" >> "$REPORT_FILE" 2>&1

echo "Running JSDoc detection..."
bash "$SCRIPT_DIR/checks/jsdoc.sh" "$FRONTEND_PATH" $TS_FILES >> "$REPORT_FILE" 2>&1

{
  echo "---"
  echo ""
} >> "$REPORT_FILE"

# ===== SECTION 2: PER-FILE CHECKS =====
{
  echo "## 2. Per-File Checks"
  echo ""
} >> "$REPORT_FILE"

# TypeScript files
if [ -n "$TS_FILES" ]; then
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      echo "Checking: $file"
      {
        echo "### File: \`$file\`"
        echo ""
      } >> "$REPORT_FILE"

      bash "$SCRIPT_DIR/checks/ts-checks.sh" "$FRONTEND_PATH/$file" >> "$REPORT_FILE" 2>&1

      # Class structure check for component/service/etc files
      if echo "$file" | grep -qE '\.(component|service|repository|directive|pipe)\.ts$'; then
        {
          echo "**Class Structure**"
          echo ""
        } >> "$REPORT_FILE"
        CLASS_OUTPUT=$(node "$SCRIPT_DIR/dist/class-structure.js" "$FRONTEND_PATH/$file" 2>/dev/null) && {
          echo "$CLASS_OUTPUT" >> "$REPORT_FILE"
        } || {
          echo "- [ ] **Class structure**: Could not analyze (ts-morph error)" >> "$REPORT_FILE"
        }
        echo "" >> "$REPORT_FILE"
      fi

      echo "---" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
    fi
  done <<< "$TS_FILES"
fi

# HTML files
if [ -n "$HTML_FILES" ]; then
  while IFS= read -r file; do
    if [ -n "$file" ]; then
      echo "Checking: $file"
      {
        echo "### File: \`$file\`"
        echo ""
      } >> "$REPORT_FILE"

      bash "$SCRIPT_DIR/checks/html-checks.sh" "$FRONTEND_PATH/$file" >> "$REPORT_FILE" 2>&1

      echo "---" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
    fi
  done <<< "$HTML_FILES"
fi

# SCSS files
if [ -n "$SCSS_FILES" ]; then
  {
    echo "### SCSS Files"
    echo ""
    echo "SCSS files checked by Prettier (Section 1). Duplicate selectors and complexity require judgment review."
    echo ""
    while IFS= read -r file; do
      if [ -n "$file" ]; then
        echo "- \`$file\`"
      fi
    done <<< "$SCSS_FILES"
    echo ""
    echo "---"
    echo ""
  } >> "$REPORT_FILE"
fi

# ===== SECTION 3: SUMMARY =====
# Count PASS/FAIL/REVIEW from the report
TOTAL_PASS=$(grep -c '\-\- PASS' "$REPORT_FILE" 2>/dev/null || echo "0")
TOTAL_FAIL=$(grep -c '\*\*FAIL\*\*' "$REPORT_FILE" 2>/dev/null || echo "0")
TOTAL_REVIEW=$(grep -c '\*\*REVIEW\*\*' "$REPORT_FILE" 2>/dev/null || echo "0")

{
  echo "## 3. Summary"
  echo ""
  echo "| Category | Count |"
  echo "|----------|-------|"
  echo "| PASS | $TOTAL_PASS |"
  echo "| FAIL | $TOTAL_FAIL |"
  echo "| REVIEW | $TOTAL_REVIEW |"
  echo ""
  if [ "$TOTAL_FAIL" -eq 0 ] && [ "$TOTAL_REVIEW" -eq 0 ]; then
    echo "All automated checks passed."
  else
    echo "**$TOTAL_FAIL violation(s) and $TOTAL_REVIEW item(s) to review found.**"
  fi
  echo ""
  echo "---"
  echo ""
} >> "$REPORT_FILE"

# ===== SECTION 4: JUDGMENT-BASED CHECKS =====
{
  echo "## 4. Judgment-Based Checks (Claude reviews manually)"
  echo ""
  echo "For each changed \`.ts\` component/service file:"
  echo "- [ ] Signal references use \`()\` for access"
  echo "- [ ] Prefer \`computed()\` over methods for derived values"
  echo "- [ ] All decorator-to-signal conversions updated references"
  echo "- [ ] Index.ts files exist for new directories"
  echo "- [ ] Naming conventions (PascalCase classes, camelCase vars, kebab-case files)"
  echo "- [ ] No hardcoded strings (use models/constants)"
  echo "- [ ] Every method tied to a specific requirement"
  echo "- [ ] Patterns match existing codebase patterns"
  echo "- [ ] No abstractions used only once"
  echo "- [ ] Mid-level developer readable"
  echo "- [ ] Simple first, reused existing utilities"
  echo "- [ ] No unnecessary defensive code"
  echo "- [ ] Ternary for simple conditionals (context-dependent)"
  echo "- [ ] Nullish coalescing where appropriate (context-dependent)"
  echo "- [ ] Event handlers describe action"
  echo "- [ ] Dead stores/assignments (manual inspection)"
  echo ""
  echo "For each changed \`.ts\` interface/model/type/enum file:"
  echo "- [ ] No \`any\` type"
  echo "- [ ] Proper interfaces/types defined"
  echo "- [ ] Naming conventions (PascalCase types, camelCase properties)"
  echo "- [ ] Simple first (no complex types without justification)"
  echo "- [ ] Reused existing types (not duplicating)"
  echo "- [ ] Patterns match codebase vocabulary"
  echo "- [ ] Every type has one-sentence justification"
  echo "- [ ] No single-use types (unless at boundaries)"
  echo "- [ ] Type structure is clear and readable"
  echo "- [ ] No unused imports"
  echo ""
  echo "For each changed \`.html\` file:"
  echo "- [ ] Signal access uses \`()\`"
  echo "- [ ] Template logic is simple (no complex expressions)"
  echo "- [ ] Patterns match existing templates"
  echo "- [ ] Event handlers describe action not event"
  echo "- [ ] No complex event handler expressions"
  echo "- [ ] Form labels associated with controls"
  echo ""
  echo "For each changed \`.scss\` file:"
  echo "- [ ] Selector complexity is justified"
  echo "- [ ] Patterns match existing SCSS"
  echo "- [ ] No unnecessary nesting"
  echo "- [ ] No duplicate selectors"
} >> "$REPORT_FILE"

echo ""
echo "Validation complete. Report written to: $REPORT_FILE"
