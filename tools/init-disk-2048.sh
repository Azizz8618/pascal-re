#!/bin/bash
# Prepare the writable working copy of the Д-2048 volume (package "2048").
# The EC-5061 image MD/EC5061/2348 is a full copy of the Д-2048 package on a
# 29 Mb volume, so PERSO recording happens on the copy 2348 and the system
# images stay untouched.
set -euo pipefail

VOL=${VOL:-2348}
SIMHMD=${SIMHMD:-$HOME/Yandex.Disk/simh/BESM6/MD/EC5061}
REF=${REF:-$SIMHMD/$VOL}
HOMEVOL=${HOMEVOL:-$HOME/.besm6/$VOL}

case "${1:-}" in
    -f) rm -f "$HOMEVOL" ;;
    -h|--help) echo "usage: $0 [-f]   (-f refreshes the copy from the reference)"; exit 0 ;;
esac

if [ ! -f "$REF" ]; then
    echo "reference image not found: $REF" >&2
    echo "set REF= or SIMHMD= to the EC5061 copy of the Д-2048 package" >&2
    exit 1
fi

if [ -f "$HOMEVOL" ]; then
    echo "working copy already present: $HOMEVOL (use -f to refresh)"
    exit 0
fi

mkdir -p "$(dirname "$HOMEVOL")"
cp "$REF" "$HOMEVOL"
echo "initialized $HOMEVOL from $REF"
