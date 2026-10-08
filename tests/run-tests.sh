#!/bin/bash
# PERSO functionality suite for the reconstructed Pascal-Monitor compiler:
# records PASCOMPL into a personal library on disk 2048 (working copy),
# then checks that the recorded compiler - and not the shipped overlay -
# compiles and runs sample programs.
#
# Everything runs on the working copy of the Д-2048 volume (EC-5061 image
# MD/EC5061/2348 copied to ~/.besm6/2348); the source image is checked to be
# byte-identical after the suite. Two PERSO copies are recorded on it, each with its own
# banner so that the monitor listing shows which compiler ran (the shipped
# compiler prints "PASCAL COMPILER 15.0 (15.02.82)"; the banner text passes
# through the Dubna TEXT encoding, so only digits and punctuation are safe
# to grep):
#   2000 (octal) - working library: system modular /*PASCAL from volume 2148
#                  zone 440 plus the reconstructed PASCOMPL, banner "15.1"
#   5000         - test library: same build with banner "99.9", proves that
#                  *STAND + *PERSO really invoke the recorded compiler
#
# RECORD=1 regenerates the golden files instead of comparing.
set -u
cd "$(dirname "$0")/.."

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

WORK_ZONE=${WORK_ZONE:-2000}
WORK_BANNER=${WORK_BANNER:-'PASCAL COMPILER 15.1 (08.10.26)'}
TEST_ZONE=${TEST_ZONE:-5000}
TEST_BANNER=${TEST_BANNER:-'PASCAL COMPILER 99.9 (01.01.70)'}

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

echo "== preparing the working copy of the Д-2048 volume"
SIMHMD=${SIMHMD:-$HOME/Yandex.Disk/simh/BESM6/MD/EC5061}
SRC_REF=${SRC_REF:-$SIMHMD/2348}
ref_before=$(md5sum "$SRC_REF" | awk '{print $1}')
if ! tools/init-disk-2048.sh -f; then
    echo "cannot initialize the working copy" >&2
    exit 1
fi

echo "== recording the compiler into PERSO"
if ! tools/perso-build.sh --mode=merged --zone="$WORK_ZONE" --banner="$WORK_BANNER"; then
    echo "working build failed" >&2
    exit 1
fi
pass "working library recorded at zone $WORK_ZONE"

if ! tools/perso-build.sh --mode=merged --zone="$TEST_ZONE" --banner="$TEST_BANNER"; then
    echo "test build failed" >&2
    exit 1
fi
pass "test library recorded at zone $TEST_ZONE"

echo "== functional tests through the working PERSO library"
for prog in writeln77 sieve forloop; do
    run_case "$WORK_ZONE" merged "tests/cases/$prog.pas" "$TMP/$prog.out"
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

echo "== banners: each recorded compiler must announce itself"
if grep -q '15\.1 (08\.10\.26)' "$TMP/writeln77.out" \
        && ! grep -q '15\.0 (15\.02\.82)' "$TMP/writeln77.out"; then
    pass "working banner 15.1 (08.10.26) from zone $WORK_ZONE"
else
    tail -30 "$TMP/writeln77.out"
    fail "working banner 15.1 (08.10.26) from zone $WORK_ZONE"
fi

run_case "$TEST_ZONE" merged tests/cases/writeln77.pas "$TMP/provenance.out"
if grep -q '99\.9 (01\.01\.70)' "$TMP/provenance.out" \
        && ! grep -q '15\.0 (15\.02\.82)' "$TMP/provenance.out" \
        && grep -qE '^[[:space:]]+77[[:space:]]*$' "$TMP/provenance.out"; then
    pass "test banner 99.9 (01.01.70) from zone $TEST_ZONE"
else
    tail -30 "$TMP/provenance.out"
    fail "test banner 99.9 (01.01.70) from zone $TEST_ZONE"
fi

echo "== catalog check"
tools/perso-check.sh --zone="$WORK_ZONE" > /dev/null \
    && pass "check: catalog readable" \
    || fail "check: catalog readable"
tools/perso-check.sh --zone="$TEST_ZONE" > /dev/null \
    && pass "check: test catalog readable" \
    || fail "check: test catalog readable"

echo "== reference image protection"
ref_after=$(md5sum "$SRC_REF" | awk '{print $1}')
if [ "$ref_before" = "$ref_after" ]; then
    pass "source image $SRC_REF unchanged"
else
    fail "source image $SRC_REF was modified"
fi

echo
echo "tests: $total, failures: $fails"
[ $fails -eq 0 ]
