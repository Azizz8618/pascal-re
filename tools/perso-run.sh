#!/bin/bash
# Compile and execute a Pascal program with the compiler recorded in the
# PERSO library on a BESM-6 disk volume (Dubna monitor under dispak).
#
# The *STAND card is what makes *CALL *PASCAL resolve the PASCOMPL module
# from the temporary library instead of the pre-linked system overlay;
# without it the monitor always runs the shipped compiler.
set -euo pipefail
cd "$(dirname "$0")/.."

VOL=2048
LU=40
ZONE=2000
MODE=merged
PROG=
SYS_VOL=2148
SYS_LU=41
SYS_ZONE=440

usage() {
    echo "usage: $0 <program.pas> [--zone=ZZZZ] [--vol=N] [--lu=NN] [--mode=merged|compact]"
    echo "defaults: vol=2048 lu=40 zone=2000 mode=merged (single self-contained library)"
    echo "compact mode also mounts $SYS_VOL zone $SYS_ZONE and loads it first"
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --zone=*)     ZONE=${1#*=} ;;
        --vol=*)      VOL=${1#*=} ;;
        --lu=*)       LU=${1#*=} ;;
        --mode=*)     MODE=${1#*=} ;;
        --sys-vol=*)  SYS_VOL=${1#*=} ;;
        --sys-lu=*)   SYS_LU=${1#*=} ;;
        --sys-zone=*) SYS_ZONE=${1#*=} ;;
        -h|--help)    usage 0 ;;
        -*)           echo "unknown option: $1" >&2; usage 1 ;;
        *)            PROG=$1 ;;
    esac
    shift
done

[ -n "$PROG" ] || usage 1
[ -f "$PROG" ] || { echo "program not found: $PROG" >&2; exit 1; }
[ "$MODE" = merged ] || [ "$MODE" = compact ] || { echo "bad --mode: $MODE" >&2; exit 1; }

deck=$(mktemp)
trap 'rm -f "$deck"' EXIT

{
    echo "user 419999 зс5^"
    [ "$MODE" = compact ] && echo "лен $SYS_LU($SYS_VOL)^"
    echo "лен $LU($VOL)^"
    echo "eeв1а3"
    echo "*name"
    echo "*call yesmemory"
    if [ "$MODE" = compact ]; then
        echo "*perso:$SYS_LU$SYS_ZONE"
        echo "*perso:$LU$ZONE,cont"
    else
        echo "*perso:$LU$ZONE"
    fi
    echo "*stand"
    echo "*call *pascal"
    sed 's/{/_(/g;s/}/_)/g' "$PROG"
    echo "*execute"
    echo "*end file"
    echo '``````'
    echo 'ЕКОНЕЦ'
} > "$deck"

exec dispak "$deck"
