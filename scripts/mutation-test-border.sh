#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="Amethyst/View/FocusedWindowBorder.swift"
BACKUP_FILE="${TARGET_FILE}.bak"

cleanup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        mv -f "$BACKUP_FILE" "$TARGET_FILE"
    fi
}
trap cleanup EXIT

echo "========================================="
echo "FocusedWindowBorder Mutation Testing Suite"
echo "========================================="

# Step 0: Ensure baseline tests pass
echo "[Baseline] Verifying unmutated codebase passes tests..."
rtk xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst -testPlan Amethyst test \
    -only-testing:AmethystTests/FocusedWindowBorderTests \
    -only-testing:AmethystTests/WindowManagerBorderLifecycleTests > /dev/null 2>&1
echo "  ✓ Baseline tests passed"

cp "$TARGET_FILE" "$BACKUP_FILE"

MUTANTS_TOTAL=0
MUTANTS_KILLED=0
MUTANTS_SURVIVED=0

run_mutant() {
    local name="$1"
    local expr="$2"
    MUTANTS_TOTAL=$((MUTANTS_TOTAL + 1))
    
    echo -n "[Mutant $MUTANTS_TOTAL] $name: "
    cp "$BACKUP_FILE" "$TARGET_FILE"
    
    # Apply mutation using perl for portability
    perl -0777 -pi -e "$expr" "$TARGET_FILE"
    
    if cmp -s "$BACKUP_FILE" "$TARGET_FILE"; then
        echo "FAILED TO APPLY MUTATION PATTERN"
        exit 1
    fi
    
    # Run targeted tests - a killed mutant means tests FAIL
    if rtk xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst -testPlan Amethyst test \
        -only-testing:AmethystTests/FocusedWindowBorderTests \
        -only-testing:AmethystTests/WindowManagerBorderLifecycleTests > /dev/null 2>&1; then
        echo "SURVIVED (Mutation was not caught!)"
        MUTANTS_SURVIVED=$((MUTANTS_SURVIVED + 1))
    else
        echo "KILLED ✓"
        MUTANTS_KILLED=$((MUTANTS_KILLED + 1))
    fi
}

run_mutant \
    "Invert isEligible tracked/managed check" \
    's/guard tracked && managed && spaceType == CGSSpaceTypeUser else/guard (tracked || managed) && spaceType == CGSSpaceTypeUser else/'

run_mutant \
    "Swap isEligible spaceType check" \
    's/spaceType == CGSSpaceTypeUser/spaceType != CGSSpaceTypeUser/'

run_mutant \
    "Invert isEligible space match condition" \
    's/return windowSpaceID == screenSpaceID/return windowSpaceID != screenSpaceID/'

run_mutant \
    "Invert hideIfTargetMatches equality check" \
    's/if targetWindowID == windowID/if targetWindowID != windowID/'

run_mutant \
    "Omit hide() in hideIfTargetMatches" \
    's/if targetWindowID == windowID \{\s*hide\(\)/if targetWindowID == windowID { \/* deleted *\/ /'

run_mutant \
    "Corrupt borderFrame outer inset" \
    's/return frame\.insetBy\(dx: -width, dy: -width\)/return frame.insetBy(dx: width, dy: width)/'

run_mutant \
    "Corrupt appKitFrame Y coordinate inversion" \
    's/primaryScreenHeight - frame\.maxY/primaryScreenHeight + frame.maxY/'

run_mutant \
    "Omit targetWindowID tracking in show" \
    's/targetWindowID = target/targetWindowID = nil/'

# Restore original
cleanup

echo "========================================="
SCORE=$((MUTANTS_KILLED * 100 / MUTANTS_TOTAL))
echo "Mutation Score: ${SCORE}% (${MUTANTS_KILLED}/${MUTANTS_TOTAL} mutants killed)"
if [[ $MUTANTS_SURVIVED -eq 0 ]]; then
    echo "0 survived. 100% Mutation Kill Rate Achieved!"
    echo "========================================="
    exit 0
else
    echo "$MUTANTS_SURVIVED mutant(s) survived. Tests need tightening."
    echo "========================================="
    exit 1
fi
