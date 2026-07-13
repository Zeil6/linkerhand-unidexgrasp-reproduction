#!/usr/bin/env python3
"""Validate that configured object codes have the required local resources."""
from __future__ import annotations
import argparse
from pathlib import Path
import sys

def load_yaml(path):
    try:
        import yaml
    except ImportError as exc:
        raise SystemExit("PyYAML is required: python -m pip install pyyaml") from exc
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)

def find_code(root, code):
    variants = [code, code.replace("/", "-"), code.replace("/", "_")]
    return any((root / value).exists() for value in variants)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True, help="dexgrasp working directory")
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--data-dir", default="datasetv4.1")
    parser.add_argument("--feature-dir", default="meshdatav3_pc_feat")
    parser.add_argument("--mesh-dir", default="meshdatav3_scaled")
    args = parser.parse_args()
    cfg = load_yaml(args.config)
    objects = cfg.get("env", {}).get("object_code_dict", {})
    if not objects:
        raise SystemExit("no env.object_code_dict found in config")
    roots = {
        "data": args.root / args.data_dir,
        "feature": args.root / args.feature_dir,
        "mesh": args.root / args.mesh_dir,
    }
    missing_roots = [str(path) for path in roots.values() if not path.is_dir()]
    if missing_roots:
        print("missing asset roots:")
        print("\n".join(f"  {path}" for path in missing_roots))
    failures = 0
    for code in objects:
        status = {name: find_code(path, code) for name, path in roots.items()}
        print(f"{code}: " + ", ".join(f"{name}={'ok' if ok else 'missing'}" for name, ok in status.items()))
        failures += not all(status.values())
    if missing_roots or failures:
        raise SystemExit(f"asset validation failed: {failures} incomplete object(s)")
    print("all configured objects have matching entries in the three asset roots")

if __name__ == "__main__":
    main()