#!/usr/bin/env bash
FRONTEND_PATH="$1"
cd "$FRONTEND_PATH" || exit 1

echo "### Lint"
echo ""

LINT_OUTPUT=$(npm run lint 2>&1)
LINT_EXIT=$?

if [ $LINT_EXIT -eq 0 ]; then
  echo "- [x] \`npm run lint\` -- PASS"
else
  echo "- [ ] \`npm run lint\` -- **FAIL**"
  echo ""
  echo "<details><summary>Lint errors</summary>"
  echo ""
  echo '```'
  echo "$LINT_OUTPUT" | tail -50
  echo '```'
  echo ""
  echo "</details>"
fi
echo ""
