#!/usr/bin/env bash
set -euo pipefail

ROOT="${UNIDEX_ROOT:?set UNIDEX_ROOT to the upstream repository}"
WORKDIR="$ROOT/dexgrasp_policy_l20hand/dexgrasp"
MODEL="${EXPERT_MODEL:?set EXPERT_MODEL to the official model.pt}"
GPU="${GPU:-0}"
LOGDIR="${LOGDIR:-logs/official_expert_review}"

test -f "$WORKDIR/train.py" || { echo "missing train.py under $WORKDIR"; exit 1; }
test -f "$MODEL" || { echo "expert checkpoint not found: $MODEL"; exit 1; }
case "$MODEL" in /*) ;; *) echo "EXPERT_MODEL must be an absolute path"; exit 2 ;; esac

cd "$WORKDIR"
CUDA_VISIBLE_DEVICES="$GPU" python train.py \
  --task=ShadowHandRandomLoadVision \
  --algo=dagger \
  --seed="${SEED:-0}" \
  --rl_device=cuda:0 \
  --sim_device=cuda:0 \
  --logdir="$LOGDIR" \
  --expert_model_dir="$MODEL" \
  --headless \
  --vision \
  --backbone_type="${BACKBONE:-pn}" \
  ${EXTRA_ARGS:-}