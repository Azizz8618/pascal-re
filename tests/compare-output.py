#!/usr/bin/env python3
# Golden output matcher for the PERSO tests.
# Semantics copied from ../dispak/tests/run-test.py: a '#' in the golden
# matches any character of the actual line, and a shorter golden line
# matches its actual counterpart prefix-wise.
import sys

def match_line(line, pattern):
    for c, p in zip(line, pattern):
        if p != '#' and c != p:
            return False
    return True

def main(golden_path, actual_path):
    with open(golden_path, errors='replace') as f:
        golden = [l.rstrip('\n') for l in f]
    with open(actual_path, errors='replace') as f:
        actual = [l.rstrip('\n') for l in f]
    if len(golden) != len(actual):
        print(f"line count differs: golden {len(golden)} vs actual {len(actual)}")
    for i in range(max(len(golden), len(actual))):
        g = golden[i] if i < len(golden) else ''
        a = actual[i] if i < len(actual) else ''
        if not match_line(a, g):
            print(f"mismatch at line {i + 1}:\n  golden: {g!r}\n  actual: {a!r}")
            return 1
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
