#!/usr/bin/env bash
set -euo pipefail

ROOT="${UNIDEX_ROOT:?set UNIDEX_ROOT to the upstream repository}"
WORKDIR="$ROOT/dexgrasp_policy_l20hand/dexgrasp"
MODEL="${L20_MODEL:?set L20_MODEL to the trained L20 PPO checkpoint}"
TASK="${L20_TASK:?set L20_TASK to the registered LinkerHand L20 task name}"
GPU="${GPU:-0}"
LOGDIR="${LOGDIR:-logs/l20_policy_review}"

test -f "$WORKDIR/train.py" || { echo "missing train.py under $WORKDIR"; exit 1; }
test -f "$MODEL" || { echo "L20 checkpoint not found: $MODEL"; exit 1; }
case "$MODEL" in /*) ;; *) echo "L20_MODEL must be an absolute path"; exit 2 ;; esac

cd "$WORKDIR"
CUDA_VISIBLE_DEVICES="$GPU" python train.py \
  --task="$TASK" \
  --algo=ppo \
  --seed="${SEED:-7}" \
  --rl_device=cuda:0 \
  --sim_device=cuda:0 \
  --logdir="$LOGDIR" \
  --model_dir="$MODEL" \
  --test \
  ${EXTRA_ARGS:-}