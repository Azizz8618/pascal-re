#!/bin/bash
# Compile the reconstructed Pascal-Monitor compiler (pascompl.b6) under the
# Dubna monitor in dispak and record the PASCOMPL object into a PERSO
# (personal) library on a BESM-6 disk volume.
#
# Modes:
#   merged  - load the modular system /*PASCAL (volume 2148, zone 440) into
#             the temporary library, compile, write the whole temporary
#             library: the result is a self-contained PERSO at --zone.
#             Usage: *PERSO:<LU><ZONE>, *STAND, *CALL *PASCAL.
#   compact - only the freshly compiled module is written (the monitor prints
#             "ДЛИНА LIBRARY" for just the new content). Usage needs the
#             system library first: *PERSO:410440, *PERSO:<LU><ZONE>,CONT.
#
# The write target is the working copy of the volume ($HOME/.besm6/<VOL>);
# run tools/init-disk-2048.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

VOL=2048
LU=40
ZONE=2000
MODE=merged
SRC=pascompl.b6
BANNER=
SYS_VOL=2148
SYS_LU=41
SYS_ZONE=440

usage() {
    echo "usage: $0 [--vol=N] [--lu=NN] [--zone=ZZZZ] [--mode=merged|compact]"
    echo "          [--src=file.b6] [--banner=text] [--sys-vol=N] [--sys-lu=NN] [--sys-zone=ZZZ]"
    echo "defaults: vol=2048 lu=40 zone=2000 mode=merged src=pascompl.b6 sys=2148/41/440"
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --vol=*)     VOL=${1#*=} ;;
        --lu=*)      LU=${1#*=} ;;
        --zone=*)    ZONE=${1#*=} ;;
        --mode=*)    MODE=${1#*=} ;;
        --src=*)     SRC=${1#*=} ;;
        --banner=*)  BANNER=${1#*=} ;;
        --sys-vol=*) SYS_VOL=${1#*=} ;;
        --sys-lu=*)  SYS_LU=${1#*=} ;;
        --sys-zone=*) SYS_ZONE=${1#*=} ;;
        -h|--help)   usage 0 ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

[ "$MODE" = merged ] || [ "$MODE" = compact ] || { echo "bad --mode: $MODE" >&2; exit 1; }
[ -f "$SRC" ] || { echo "source not found: $SRC" >&2; exit 1; }
command -v dispak >/dev/null || { echo "dispak not found in PATH" >&2; exit 1; }
if [ ! -f "$HOME/.besm6/$VOL" ]; then
    echo "no working copy of volume $VOL in ~/.besm6; run tools/init-disk-2048.sh" >&2
    exit 1
fi

deck=$(mktemp)
trap 'rm -f "$deck"' EXIT

{
    echo "user 419900 зс5^"
    [ "$MODE" = merged ] && echo "лен $SYS_LU($SYS_VOL)^"
    echo "лен $LU($VOL-wr)^"
    echo "EEB1A3"
    echo "*name"
    echo "*call yesmemory"
    [ "$MODE" = merged ] && echo "*perso:$SYS_LU$SYS_ZONE"
    echo "*pascal"
    # The compiler is written in Pascal-Monitor itself: reuse the proven
    # comp.sh path (brace comments translated to _(_) cards, source body
    # between the *pascal card and the *to perso trailer).
    awk '/^\*pascal$/{f=1;next} /^\*to perso:/{f=0} f' "$SRC" \
        | sed 's/{/_(/g;s/}/_)/g' \
        | if [ -n "$BANNER" ]; then
              sed "s/' PASCAL COMPILER 15.0 (15.02.82)'/' $BANNER'/"
          else
              cat
          fi
    echo "*to perso:$LU$ZONE"
    echo "*end file"
    echo '``````'
    echo 'ЕКОНЕЦ'
} > "$deck"

out=$(dispak "$deck" 2>&1)

lines=$(printf '%s\n' "$out" | grep -o '[0-9]* LINЕS SТRUСТURЕ' | awk '{print $1}')
length=$(printf '%s\n' "$out" | awk '/ДЛИНА/{print $3; exit}')

if [ -z "$lines" ] || [ -z "$length" ]; then
    echo "PERSO build failed (source lines: ${lines:-none}, library length: ${length:-none})" >&2
    printf '%s\n' "$out" | tail -20 >&2
    exit 1
fi

# The Dubna TEXT catalog decodes the module name with Cyrillic look-alikes;
# "МРL" is the tail of PASCOMPL and is unique to the recorded entry.
if ! besmtool view "$VOL" --start=$((8#$ZONE)) --length=1 --encoding=t \
        | grep -q 'МРL'; then
    echo "catalog entry for PASCOMPL not found at volume $VOL zone $ZONE" >&2
    exit 1
fi

echo "mode=$MODE volume=$VOL lu=$LU zone=$ZONE lines=$lines library_zones=$length"
echo "PERSO library recorded: *perso:$LU$ZONE"
