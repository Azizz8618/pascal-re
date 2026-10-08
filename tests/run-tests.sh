#!/bin/bash
# PERSO functionality suite for the reconstructed Pascal-Monitor compiler:
# records PASCOMPL into a personal library on disk 2048 (working copy),
# then checks that the recorded compiler - and not the shipped overlay -
# compiles and runs sample programs.
#
# Zones used on the target volume:
#   2000 (octal) - merged self-contained library (system modular /*PASCAL
#                  from volume 2148 zone 440 plus the new PASCOMPL)
#   4000         - compact library: only the new PASCOMPL module
#   5000         - merged variant with a replaced banner, used to prove
#                  that *STAND + *PERSO really invoke the recorded compiler
#
# RECORD=1 regenerates the golden files instead of comparing.
set -u
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

MERGED_ZONE=${MERGED_ZONE:-2000}
COMPACT_ZONE=${COMPACT_ZONE:-4000}
VARIANT_ZONE=${VARIANT_ZONE:-5000}
VARIANT_BANNER='PERSO PROVENANCE OK'

total=0
fails=0
pass() { echo "ok   - $1"; total=$((total + 1)); }
fail() { echo "FAIL - $1"; total=$((total + 1)); fails=$((fails + 1)); }

# The monitor prints the current date in its page headers; mask it exactly
# like the wildcard convention of ../dispak/tests/run-test.py.
mask() { sed -E '/ М[13]/s/[0-9]{2}\.[0-9]{2}\.[0-9]{2}/##.##.##/g'; }

run_case() { # zone mode program target
    tools/perso-run.sh "$3" --zone="$1" --mode="$2" > "$4" 2>&1
    mask < "$4" > "$4.masked"
}

echo "== preparing the working copy of disk 2048"
rm -f "$HOME/.besm6/2048"
if ! tools/init-disk-2048.sh; then
    echo "cannot initialize the working copy" >&2
    exit 1
fi

echo "== recording the compiler into PERSO"
if ! tools/perso-build.sh --mode=merged --zone="$MERGED_ZONE"; then
    echo "merged build failed" >&2
    exit 1
fi
pass "merged library recorded at zone $MERGED_ZONE"

if ! tools/perso-build.sh --mode=compact --zone="$COMPACT_ZONE"; then
    echo "compact build failed" >&2
    exit 1
fi
pass "compact library recorded at zone $COMPACT_ZONE"

if ! tools/perso-build.sh --mode=merged --zone="$VARIANT_ZONE" --banner="$VARIANT_BANNER"; then
    echo "variant build failed" >&2
    exit 1
fi
pass "banner variant recorded at zone $VARIANT_ZONE"

echo "== functional tests through the merged PERSO library"
for prog in writeln77 sieve forloop; do
    run_case "$MERGED_ZONE" merged "tests/cases/$prog.pas" "$TMP/$prog.out"
    if [ "${RECORD:-0}" = 1 ]; then
        cp "$TMP/$prog.out.masked" "tests/golden/$prog.txt"
        echo "recorded tests/golden/$prog.txt"
        continue
    fi
    if ! tests/compare-output.py "tests/golden/$prog.txt" "$TMP/$prog.out.masked" > "$TMP/$prog.diff"; then
        echo "---- $prog"
        cat "$TMP/$prog.diff"
        tail -40 "$TMP/$prog.out"
        fail "merged: $prog"
    else
        pass "merged: $prog"
    fi
done

echo "== functional test through the compact PERSO library"
run_case "$COMPACT_ZONE" compact tests/cases/writeln77.pas "$TMP/compact.out"
if grep -qE '^[[:space:]]+77[[:space:]]*$' "$TMP/compact.out" \
        && ! grep -q 'ОТСУТСТВУЕТ' "$TMP/compact.out"; then
    pass "compact (two libraries): writeln77 runs"
else
    tail -30 "$TMP/compact.out"
    fail "compact (two libraries): writeln77 runs"
fi

echo "== provenance: the recorded compiler must replace the overlay"
run_case "$VARIANT_ZONE" merged tests/cases/writeln77.pas "$TMP/variant.out"
if grep -q '15\.0 (15\.02\.82)' "$TMP/variant.out"; then
    fail "provenance: system overlay banner still printed from zone $VARIANT_ZONE"
elif ! grep -qE '^[[:space:]]+77[[:space:]]*$' "$TMP/variant.out"; then
    tail -30 "$TMP/variant.out"
    fail "provenance: program did not run through the variant compiler"
else
    pass "provenance: variant compiler banner replaces the system one"
fi

echo "== catalog check"
tools/perso-check.sh --zone="$MERGED_ZONE" > /dev/null \
    && pass "check: catalog readable" \
    || fail "check: catalog readable"

echo
echo "tests: $total, failures: $fails"
[ $fails -eq 0 ]
