#!/usr/bin/env python3
"""Inspect a PyTorch checkpoint without constructing the task."""
from __future__ import annotations
import argparse
from collections.abc import Mapping
from pathlib import Path
import torch

def unwrap(obj):
    if not isinstance(obj, Mapping):
        raise TypeError(f"checkpoint root is {type(obj).__name__}, expected a mapping")
    for key in ("state_dict", "model_state_dict", "model", "policy"):
        value = obj.get(key)
        if isinstance(value, Mapping) and value:
            print(f"using nested mapping: {key}")
            return value
    return obj

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("checkpoint", type=Path)
    parser.add_argument("--max-rows", type=int, default=80)
    args = parser.parse_args()
    if not args.checkpoint.is_file():
        raise SystemExit(f"checkpoint not found: {args.checkpoint}")
    raw = torch.load(args.checkpoint, map_location="cpu")
    state = unwrap(raw)
    tensors = [(k, v) for k, v in state.items() if torch.is_tensor(v)]
    print(f"tensor parameters: {len(tensors)}")
    for key, value in tensors[: args.max_rows]:
        print(f"{key:72s} shape={tuple(value.shape)} dtype={value.dtype}")
    matrices = [(k, v) for k, v in tensors if v.ndim == 2]
    if matrices:
        key, value = matrices[0]
        print(f"\nfirst 2-D weight: {key} {tuple(value.shape)}")
        print(f"candidate input dimension: {value.shape[1]}")
    action_hints = [(k, tuple(v.shape)) for k, v in tensors if "log_std" in k or k.endswith("sigma")]
    if action_hints:
        print("action-dimension hints:")
        for item in action_hints:
            print(" ", item)
    print("\nInterpret shapes together with the task and model class; names alone are not proof.")

if __name__ == "__main__":
    main()