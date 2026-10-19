#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="Amethyst/Managers/WindowTransitionCoordinator.swift"
BACKUP_FILE="${TARGET_FILE}.bak"

cleanup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        mv -f "$BACKUP_FILE" "$TARGET_FILE"
    fi
}
trap cleanup EXIT

echo "========================================="
echo "WindowTransitionCoordinator Mutation Testing Suite"
echo "========================================="

# Step 0: Ensure baseline tests pass
echo "[Baseline] Verifying unmutated codebase passes tests..."
rtk run xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst test \
    -only-testing:AmethystTests/WindowTransitionCoordinatorTests \
    CODE_SIGNING_ALLOWED=NO > /dev/null 2>&1
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

    # Apply mutation using perl
    perl -0777 -pi -e "$expr" "$TARGET_FILE"

    if cmp -s "$BACKUP_FILE" "$TARGET_FILE"; then
        echo "FAILED TO APPLY MUTATION PATTERN"
        exit 1
    fi

    # Run targeted tests - a killed mutant means tests FAIL
    if rtk run xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst test \
        -only-testing:AmethystTests/WindowTransitionCoordinatorTests \
        CODE_SIGNING_ALLOWED=NO > /dev/null 2>&1; then
        echo "SURVIVED (Mutation was not caught!)"
        MUTANTS_SURVIVED=$((MUTANTS_SURVIVED + 1))
    else
        echo "KILLED ✓"
        MUTANTS_KILLED=$((MUTANTS_KILLED + 1))
    fi
}

run_mutant \
    "Re-introduce isWindowFloating check in swapFocusedWindowScreenClockwise" \
    's/func swapFocusedWindowScreenClockwise\(\) \{\s*guard let focusedWindow = Window\.currentlyFocused\(\) else/func swapFocusedWindowScreenClockwise() {\n        guard let focusedWindow = Window.currentlyFocused(), target?.isWindowFloating(focusedWindow) == false else/'

run_mutant \
    "Re-introduce isWindowFloating check in swapFocusedWindowScreenCounterClockwise" \
    's/func swapFocusedWindowScreenCounterClockwise\(\) \{\s*guard let focusedWindow = Window\.currentlyFocused\(\) else/func swapFocusedWindowScreenCounterClockwise() {\n        guard let focusedWindow = Window.currentlyFocused(), target?.isWindowFloating(focusedWindow) == false else/'

run_mutant \
    "Invert clockwise swap direction" \
    's/nextScreenIndexClockwise\(from: screen\)/nextScreenIndexCounterClockwise(from: screen)/'

run_mutant \
    "Invert counter-clockwise swap direction" \
    's/nextScreenIndexCounterClockwise\(from: screen\)/nextScreenIndexClockwise(from: screen)/'

run_mutant \
    "Omit resetFocus on nil focused window in swapFocusedWindowScreenClockwise" \
    's/func swapFocusedWindowScreenClockwise\(\) \{\s*guard let focusedWindow = Window\.currentlyFocused\(\) else \{\s*target\?\.executeTransition\(\.resetFocus\)/func swapFocusedWindowScreenClockwise() {\n        guard let focusedWindow = Window.currentlyFocused() else {\n            \/* omitted *\//'

run_mutant \
    "Omit resetFocus on nil focused window in swapFocusedWindowScreenCounterClockwise" \
    's/func swapFocusedWindowScreenCounterClockwise\(\) \{\s*guard let focusedWindow = Window\.currentlyFocused\(\) else \{\s*target\?\.executeTransition\(\.resetFocus\)/func swapFocusedWindowScreenCounterClockwise() {\n        guard let focusedWindow = Window.currentlyFocused() else {\n            \/* omitted *\//'

run_mutant \
    "Corrupt target screen parameter in swapFocusedWindowScreenClockwise" \
    's/moveWindowToScreen\(focusedWindow, screen: nextScreen\)/moveWindowToScreen(focusedWindow, screen: screen)/'

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
    echo "${MUTANTS_SURVIVED} mutants survived."
    echo "========================================="
    exit 1
fi
