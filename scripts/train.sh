#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-state}"
ROOT="${UNIDEX_ROOT:-$(pwd)}"
POLICY_DIR="$ROOT/dexgrasp_policy_l20hand/dexgrasp"

case "$MODE" in
  state) SCRIPT="$POLICY_DIR/script/run_train_ppo_state.sh" ;;
  vision) SCRIPT="$POLICY_DIR/script/run_train_ppo_vision.sh" ;;
  *) echo 'Usage: train.sh {state|vision}'; exit 2 ;;
esac

test -f "$SCRIPT" || { echo "ERROR: upstream script not found: $SCRIPT"; exit 1; }
echo "Project root: $ROOT"
echo "Training mode: $MODE"
echo "Launching: $SCRIPT"
cd "$POLICY_DIR"
bash "$SCRIPT"