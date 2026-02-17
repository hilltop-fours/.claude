#!/usr/bin/env bash
FRONTEND_PATH="$1"
cd "$FRONTEND_PATH" || exit 1

echo "### Build"
echo ""

BUILD_OUTPUT=$(npm run build 2>&1)
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
  echo "- [x] \`npm run build\` -- PASS"
else
  echo "- [ ] \`npm run build\` -- **FAIL**"
  echo ""
  echo "<details><summary>Build errors</summary>"
  echo ""
  echo '```'
  echo "$BUILD_OUTPUT" | tail -50
  echo '```'
  echo ""
  echo "</details>"
fi
echo ""
