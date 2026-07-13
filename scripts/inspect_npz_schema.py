#!/usr/bin/env python3
"""List NPZ keys, shapes and dtypes before a task consumes the file."""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("npz", type=Path)
    parser.add_argument("--expected", nargs="*", default=[])
    args = parser.parse_args()
    if not args.npz.is_file():
        raise SystemExit(f"NPZ not found: {args.npz}")
    with np.load(args.npz, allow_pickle=False) as data:
        keys = list(data.files)
        print("keys:", keys)
        for key in keys:
            value = data[key]
            finite = bool(np.isfinite(value).all()) if np.issubdtype(value.dtype, np.number) else "n/a"
            print(f"{key:20s} shape={value.shape!s:20s} dtype={value.dtype} finite={finite}")
        missing = [key for key in args.expected if key not in data]
    if missing:
        raise SystemExit(f"missing expected keys: {missing}")
    if keys == ["arr_0", "arr_1", "arr_2"]:
        print("warning: default NumPy keys detected; do not rename blindly without checking joint semantics")

if __name__ == "__main__":
    main()