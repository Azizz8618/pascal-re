#!/bin/bash
# Inspect a PERSO library recorded on a BESM-6 disk volume: show its catalog
# header, and optionally extract the object module body.
#
# A personal library occupies zones ZONE..ZONE+n-1; the catalog lives in the
# first two zones and the module data starts at zone ZONE+2 (format.md,
# matching dtran/decomp/pasdms.sh). besmtool takes decimal zone numbers,
# the monitor cards take octal ones.
set -euo pipefail
cd "$(dirname "$0")/.."

VOL=2048
ZONE=2000
ZONES=
DUMP=

usage() {
    echo "usage: $0 [--vol=N] [--zone=ZZZZ] [--zones=NN] [--dump=file.o]"
    echo "  --zones=NN  total library length in zones, as reported by"
    echo "              tools/perso-build.sh (needed only with --dump)"
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --vol=*)   VOL=${1#*=} ;;
        --zone=*)  ZONE=${1#*=} ;;
        --zones=*) ZONES=${1#*=} ;;
        --dump=*)  DUMP=${1#*=} ;;
        -h|--help) usage 0 ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

zd=$((8#$ZONE))
echo "catalog at volume $VOL zone $ZONE (octal):"
besmtool view "$VOL" --start=$zd --length=1 --encoding=t

if ! besmtool view "$VOL" --start=$zd --length=1 --encoding=t | grep -q 'МРL'; then
    echo "PASCOMPL entry not found" >&2
    exit 1
fi
echo "PASCOMPL entry: present"

if [ -n "$DUMP" ]; then
    [ -n "$ZONES" ] || { echo "--dump needs --zones=NN from the build report" >&2; exit 1; }
    body=$((8#$ZONES - 2))
    besmtool dump "$VOL" --start=$((zd + 2)) --length=$body --to-file="$DUMP"
    echo "dumped $body zones (octal $ZONES minus the 2 catalog zones) to $DUMP"
fi
