#!/bin/bash
# Prepare the writable working copy of BESM-6 disk 2048 in ~/.besm6.
# dispak and besmtool look up volume images in $HOME/.besm6 first and only
# then in /usr/local/share/besm6, so all PERSO recording lands on this copy
# and the reference images are never modified.
set -euo pipefail

VOL=${VOL:-2048}
REF=${REF:-/usr/local/share/besm6/$VOL}
HOMEVOL=${HOMEVOL:-$HOME/.besm6/$VOL}

case "${1:-}" in
    -f) rm -f "$HOMEVOL" ;;
    -h|--help) echo "usage: $0 [-f]   (-f refreshes the copy from the reference)"; exit 0 ;;
esac

if [ ! -f "$REF" ]; then
    echo "reference image not found: $REF" >&2
    exit 1
fi

if [ -f "$HOMEVOL" ]; then
    echo "working copy already present: $HOMEVOL (use -f to refresh)"
    exit 0
fi

mkdir -p "$(dirname "$HOMEVOL")"
cp "$REF" "$HOMEVOL"
echo "initialized $HOMEVOL from $REF"
